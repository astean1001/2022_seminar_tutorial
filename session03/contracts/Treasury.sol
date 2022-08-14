pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ImUST {
	function isVault(address _vault) view external returns (bool);
}

interface IStrategy {
	function setCToken(address _ctoken) external;
	function getTokens(uint256 amount) external;
	function execute(uint256 amount) external payable;
}

interface IWETH {
	function withdraw(uint wad) external;
}

contract Treasury is Ownable{

	address public mUST;
	address public WETH;

	modifier onlyVault() { 
		require(ImUST(mUST).isVault(msg.sender), "mUST: msg.sender is not Vault");
		_;
	}

	mapping(address => address) public strategies;

	event strategyModified(address _strategy, address _baseToken);
	event strategyExecuted(address _strategy, uint256 _amount);

	constructor(address _mUST, address _WETH) {
		mUST = _mUST;
		WETH = _WETH;
	}

	function modifyStrategy(address _baseToken, address _strategy) onlyOwner public {
		strategies[_baseToken] = _strategy;
		emit strategyModified(_strategy, _baseToken);
	}

	function executeStrategy(address _baseToken, uint256 _amount) public payable {
		//IERC20(_baseToken).transfer(strategies[_baseToken], _amount);
		safeTransfer(_baseToken, strategies[_baseToken], _amount);
		(bool success, bytes memory data) = strategies[_baseToken].call{ value: msg.value }(
            abi.encodeWithSignature("execute(uint256)", _amount)
        );
        require(success, "Treasury: Strategy execution is not successful");
	}

	function getTokenTo(address _baseToken, uint256 _amount, address _to) onlyVault public payable {
		uint256 curBal = IERC20(_baseToken).balanceOf(address(this));
		if (curBal >= 0 && curBal < _amount) { IStrategy(strategies[_baseToken]).getTokens(_amount - curBal); }
		//IERC20(_baseToken).transfer(_to, _amount);
		safeTransfer(_baseToken, _to, _amount);
	}

	function safeTransfer(address token, address to, uint256 amount) private {
		(bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "Treasury: safeTransfer is not successful");
	}

	function getETHTo(uint256 _amount, address payable _to) onlyVault public {
		uint256 curBal = IERC20(WETH).balanceOf(address(this));
		if (curBal >= 0 && curBal < _amount) { IStrategy(strategies[WETH]).getTokens(_amount - curBal); }
		IWETH(WETH).withdraw(_amount);
		_to.call{value: address(this).balance}("");
	}

	receive() external payable {}

	fallback() external payable {}
}