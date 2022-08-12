pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MockCompound is ERC20, ERC20Burnable {
	constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

	function redeemUnderlying(uint256 amount) public returns (uint256) {
		return 0;
	}

	function mint(uint256 amount) public returns (uint256) {
		_mint(msg.sender, amount);
		return 0;
	}
}