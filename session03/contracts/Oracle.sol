pragma solidity 0.8.16;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Oracle {
	IERC20 mUST;

	constructor(address _mUST) {
		mUST = IERC20(_mUST);
	}

	function calcMustardPrice(IERC20 token, address pair) public view returns (uint256) {
		return (mUST.balanceOf(pair) * token.balanceOf(pair)) / (mUST.balanceOf(pair) - 1e18) - token.balanceOf(pair);
	}
}