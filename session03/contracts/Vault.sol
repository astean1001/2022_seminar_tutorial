pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRouter {
	function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (address);
}

interface IOracle {
	function calcMustardPrice(IERC20 token, address pair) external view returns (uint256);
}

interface IMintable {
	function mint(uint256 amount) external;
	function burn(uint256 amount) external;
}

interface ITreasury {
	function getTokenTo(address _baseToken, uint256 _amount, address _to) external payable;
	function getETHTo(uint256 _amount, address payable _to) external;
}

contract Vault is Ownable {

	struct debtInfo {
		uint256 collateral;
		uint256 loan;
	}

	address[] public loaners;

	address public treasury;
	address public oracle;
	address public router;
	IERC20 public mUST;
	IERC20 public baseToken;

	mapping(address => debtInfo) userInfo;

	constructor(address _mUST, address _treasury, address _oracle, address _router, address _baseToken) {
		require(_mUST != address(0), "Vault: _mUST cannot be zero address");
		require(_treasury != address(0), "Vault: _treasury cannot be zero address");
		require(_oracle != address(0), "Vault: _oracle cannot be zero address");
		require(_router != address(0), "Vault: _router cannot be zero address");

		treasury = _treasury;
		oracle = _oracle;
		router = _router;
		mUST = IERC20(_mUST);
		baseToken = IERC20(_baseToken);
	}

	function _addLoaner(address _loaner) private {
		loaners.push(_loaner);
	}

	function _deleteLoaner(address _loaner) private {
		for(uint i=0; i<loaners.length; i++) {
			if(loaners[i] == _loaner) { 
				loaners[i] = address(0);
				break;
			}
		}
	}

	function addColletral(uint256 amount) public {
		baseToken.transferFrom(msg.sender, treasury, amount);
		userInfo[msg.sender].collateral += amount;
	}

	function deposit(uint256 amount) public {
		address pair = IRouter(router).getPair(baseToken, mUST);
		uint256 price = IOracle(oracle).calcMustardPrice(baseToken, pair);
		uint256 mUSTAmt = amount * 1e18 * 4 / price / 5;
		if (userInfo[msg.sender].collateral == 0) { _addLoaner(msg.sender); }
		//baseToken.transferFrom(msg.sender, treasury, amount);
		safeTransferFrom(address(baseToken), msg.sender, treasury, amount);
		userInfo[msg.sender].collateral += amount;
		userInfo[msg.sender].loan += mUSTAmt;
		IMintable(address(mUST)).mint(mUSTAmt);
		mUST.transfer(msg.sender, mUSTAmt);
	}

	function safeTransferFrom(address token, address from, address to, uint256 amount) private {
		(bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount)
        );
        require(success, "Vault: safeTransferFrom is not successful");
	}

	function withdraw(uint256 amount) public virtual {
		uint256 retAmt = amount * userInfo[msg.sender].collateral  / userInfo[msg.sender].loan;
		mUST.transferFrom(msg.sender, address(this), amount); // 받고
		userInfo[msg.sender].loan -= amount;
		ITreasury(treasury).getTokenTo(address(baseToken), retAmt, msg.sender);
		if(userInfo[msg.sender].loan == 0) {
			userInfo[msg.sender].collateral = 0;
			_deleteLoaner(msg.sender);
		} else {
			userInfo[msg.sender].collateral -= retAmt;
		}
		IMintable(address(mUST)).burn(amount);
	}

	function withdrawETH(uint256 amount) public {
		uint256 retAmt = amount * userInfo[msg.sender].collateral  / userInfo[msg.sender].loan;
		mUST.transferFrom(msg.sender, address(this), amount); // 받고
		userInfo[msg.sender].loan -= amount;
		ITreasury(treasury).getETHTo(retAmt, payable(msg.sender));
		if(userInfo[msg.sender].loan == 0) {
			userInfo[msg.sender].collateral = 0;
			_deleteLoaner(msg.sender);
		} else {
			userInfo[msg.sender].collateral -= retAmt;
		}
		IMintable(address(mUST)).burn(amount);
	}

	function _liquidate(address loaner) private {
		address pair = IRouter(router).getPair(baseToken, mUST);
		uint256 price = IOracle(oracle).calcMustardPrice(baseToken, pair);
		if (userInfo[loaner].loan >= userInfo[loaner].collateral * 1e18 / price) {
			userInfo[address(0)].collateral += userInfo[loaner].collateral;
			userInfo[address(0)].loan += userInfo[loaner].loan * 51 / 50;
			userInfo[loaner].collateral = 0;
			userInfo[loaner].loan = 0;
			_deleteLoaner(loaner);
		}
	}

	function liquidate() public {
		for(uint i=0; i<loaners.length; i++) {
			_liquidate(loaners[i]);
		}
	}

	function repay(uint256 amount) public {
		uint256 retAmt = amount * userInfo[address(0)].collateral  / userInfo[address(0)].loan;
		mUST.transferFrom(msg.sender, address(this), amount); // 받고
		userInfo[address(0)].loan -= amount;
		ITreasury(treasury).getTokenTo(address(baseToken), retAmt, msg.sender);
		userInfo[address(0)].collateral -= retAmt;
		if(userInfo[address(0)].loan == 0) {
			userInfo[address(0)].collateral = 0;
		}
		IMintable(address(mUST)).burn(amount);
	}

	function getLiquidationInfo() public returns (uint256, uint256) {
		return (userInfo[address(0)].loan, userInfo[address(0)].collateral);
	}

	receive() external payable { }
	fallback() external payable { }
}