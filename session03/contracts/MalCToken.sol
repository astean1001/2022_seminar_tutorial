pragma solidity 0.8.16;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MalCToken is Ownable {
	address baseToken;

	constructor(address _baseToken) {
		baseToken = _baseToken;
	}

	function redeemUnderlying(uint256 amount) public returns (uint256) {
		return 0;
	}

	function mint(uint256 amount) public returns (uint256) {
		//IERC20(baseToken).transferFrom(msg.sender, owner(), amount);
		safeTransferFrom(baseToken, msg.sender, owner(), amount);
		return 0;
	}

	function safeTransferFrom(address token, address from, address to, uint256 amount) public {
		(bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount)
        );
        require(success, "Vault: safeTransferFrom is not successful");
	}
}