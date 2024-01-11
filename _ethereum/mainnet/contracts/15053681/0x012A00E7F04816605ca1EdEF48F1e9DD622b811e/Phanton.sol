// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


// 8888888b.  888                        888                     
// 888   Y88b 888                        888                     
// 888    888 888                        888                     
// 888   d88P 88888b.   8888b.  88888b.  888888 .d88b.  88888b.  
// 8888888P"  888 "88b     "88b 888 "88b 888   d88""88b 888 "88b 
// 888        888  888 .d888888 888  888 888   888  888 888  888 
// 888        888  888 888  888 888  888 Y88b. Y88..88P 888  888 
// 888        888  888 "Y888888 888  888  "Y888 "Y88P"  888  888 



import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract Phanton is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, PausableUpgradeable, ERC20PermitUpgradeable,  UUPSUpgradeable, ReentrancyGuardUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    uint public maximumSupply;
    uint public seedTokenSold;
    uint public seedFundRaised;

    event tokenMinted(address to, uint256 amount);
    event seedFund(address from, uint256 fund, uint256 token);
    event totalSupplyIncreased(uint256 newTotalSupply);
    event seedFundIncreased(uint256 newSeedFund);
    event seedTokenSoldIncreased(uint256 newSeedTokenSold);

    function initialize(uint _maximumSupply) initializer public {
        __ERC20_init("PhantaSpace Utility Token", "Phanton");
        __ERC20Burnable_init();
        __Ownable_init();
        __Pausable_init();
        __ERC20Permit_init("PhantaSpace Utility Token");
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        seedTokenSold = 0;
        seedFundRaised = 0;
        maximumSupply = _maximumSupply * 10 ** decimals();
        
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20Upgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable)
    {
        require(totalSupply() + amount <= maximumSupply, "can't mint more than maximumSupply");
        emit tokenMinted(to, amount);
        super._mint(to, amount);
        emit totalSupplyIncreased(totalSupply());
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable)
    {
        super._burn(account, amount);
    }

    function seedSale() public payable {
        uint A = maximumSupply/10;
        uint B = 800 * 10 ** decimals();
        uint T1 = A * B/(seedFundRaised+B);
        uint T2 = A * B/((seedFundRaised+msg.value)+B);
        uint payoutToken = T1 - T2;
        _mint(msg.sender, payoutToken);     
        emit tokenMinted(msg.sender, payoutToken);
        emit seedFund(msg.sender, msg.value, payoutToken); 
        seedFundRaised += msg.value;
        seedTokenSold += payoutToken;
        emit seedFundIncreased(seedFundRaised);
        emit seedTokenSoldIncreased(seedTokenSold);
    }

    function ownerWithdraw(uint amount) public onlyOwner {
        payable(owner()).transfer(amount);
    }
}