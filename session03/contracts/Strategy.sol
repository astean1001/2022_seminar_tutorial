import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity 0.8.16;
import "hardhat/console.sol";

interface ICtoken {
	function redeemUnderlying(uint256 amount) external returns (uint256);
	function mint(uint256 amount) external returns (uint256);
}

contract Strategy {
	ICtoken public ctoken;
	address public baseToken;
	address public treasury;

	constructor(address _ctoken, address _baseToken, address _treasury) {
		ctoken = ICtoken(_ctoken);
		baseToken = _baseToken;
		treasury = _treasury;
	}

	function setCToken(address _ctoken) public {
		ctoken = ICtoken(_ctoken);
	}


	function getTokens(uint256 amount) public {
		require(ctoken.redeemUnderlying(amount) == 0, "Strategy: Redeem failed");
		IERC20(baseToken).transfer(treasury, amount);
	}

	function execute(uint256 amount) public payable {
		IERC20(baseToken).approve(address(ctoken), amount); 
		safeApprove(baseToken, address(ctoken), amount);
		//require(ctoken.mint(amount) == 0, "Strategy: Mint failed"); 
	}

	function safeApprove(address token, address to, uint256 amount) private {
		(bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(success, "Strategy: safeApprove is not successful");
	}

	receive() external payable {}

	fallback() external payable {}
}