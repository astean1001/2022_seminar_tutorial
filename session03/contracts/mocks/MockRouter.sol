pragma solidity 0.8.16;

contract MockRouter {
	mapping(address => mapping(address => address)) pairs;

	constructor() {}

	function addPair(address tokenA, address tokenB, address pair) public {
		pairs[tokenA][tokenB] = pair;
	}
	function getPair(address tokenA, address tokenB) public view returns(address) { 
		return pairs[tokenA][tokenB];
	}
}