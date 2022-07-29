// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC20.sol";

contract ExampleToken is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20() {
        name = _name;
        symbol = _symbol;
        _mint(100 * 10 ** uint(decimals));
    }

    function mint(uint amount) external {
        _mint(amount);
    }

    function burn(uint amount) external {
        _burn(amount);
    }
}

