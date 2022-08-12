pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IFlashloanReceiver {
	function flashloanReceived (address token, uint256 amount) external;
}

contract MockPair is ReentrancyGuard {
	address public tokenA;
	address public tokenB;

	uint256 tokenAmountA;
	uint256 tokenAmountB;
	uint256 K;

	constructor(address _tokenA, address _tokenB) {
		tokenA = _tokenA;
		tokenB = _tokenB;
	}

	function flashloan(address token, uint256 amount, address to) public nonReentrant {
		require(token == tokenA || token == tokenB, "MockPair: Not target pair");
		tokenAmountA = IERC20(tokenA).balanceOf(address(this));
		tokenAmountB = IERC20(tokenB).balanceOf(address(this));
		K = tokenAmountA * tokenAmountB;
		IERC20(token).transfer(to, amount);
		IFlashloanReceiver(to).flashloanReceived(token, amount);
		uint256 before = token==tokenA?tokenAmountA:tokenAmountB;
		require(IERC20(token).balanceOf(address(this)) >= before, "MockPair: Flashloan failed");
	}

	function swap(address token, uint256 amount) public {
		if(token == tokenA) {
			uint256 swapAmt = K / (tokenAmountA - amount) - tokenAmountB;
			tokenAmountA += amount;
			tokenAmountB -= swapAmt;
			//IERC20(token).transferFrom(msg.sender, address(this), amount);
			safeTransferFrom(token, msg.sender, address(this), amount);
			IERC20(tokenB).transfer(msg.sender, swapAmt);
		}
		else {
			uint256 swapAmt = K / (tokenAmountB - amount) - tokenAmountA;
			tokenAmountB += amount;
			tokenAmountA -= swapAmt;
			IERC20(token).transferFrom(msg.sender, address(this), amount);
			IERC20(tokenA).transfer(msg.sender, swapAmt);
		}
	}

	function safeTransferFrom(address token, address from, address to, uint256 amount) private {
		(bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount)
        );
        require(success, "Vault: safeTransferFrom is not successful");
	}
}