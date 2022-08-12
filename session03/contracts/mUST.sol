pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract mUST is ERC20, ERC20Burnable, Ownable {
	address[] public vaults;

	event vaultAdded(address _vault);
	event vaultDeleted(address _vault);

	modifier onlyVault() { 
		require(isVault(msg.sender), "mUST: msg.sender is not Vault");
		_;
	}

	constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

	function addVault(address _vault) onlyOwner public {
		vaults.push(_vault);
		emit vaultAdded(_vault);
	}

	function deleteVault(address _vault) onlyOwner public {
		for(uint i=0; i<vaults.length; i++) {
			if(vaults[i] == _vault) { 
				vaults[i] = vaults[vaults.length - 1]; 
				break;
			}
		}
		vaults.pop();
		emit vaultDeleted(_vault);
	}

	function mint(uint256 amount) onlyVault public {
		_mint(msg.sender, amount);
	}

	function burn(uint256 amount) onlyVault public override {
		super.burn(amount);
	}

	function burnFrom(address account, uint256 amount) onlyVault public override {
        super.burnFrom(account, amount);
	}

	function isVault(address _vault) view public returns (bool) {
		for(uint i=0; i<vaults.length; i++) {
			if(vaults[i] == _vault) return true;
		}
		return false;
	}
}
