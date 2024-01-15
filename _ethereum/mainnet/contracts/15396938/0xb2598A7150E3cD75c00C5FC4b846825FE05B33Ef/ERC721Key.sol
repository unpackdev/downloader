//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC721AUpgradeable.sol";
import "./OpenSeaGasFreeListing.sol";
import "./StringsUpgradeable.sol";

contract ApiensGenesisBagERC721 is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721AUpgradeable 
{
    string public baseURI;
    mapping (address => bool) private _minters;

    function initialize() public initializerERC721A initializer {
        __ERC721A_init("Apiens Genesis Bag", "ABG");
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    modifier onlyMinter {
        require(isMinter(msg.sender), "Only minters can mint");
        _;
    }

    function mint(address to_, uint256 amount_) external onlyMinter nonReentrant whenNotPaused {
        _safeMint(to_, amount_);
    }

    function setMinters(address minter_, bool val_) external onlyOwner {
        _minters[minter_] = val_;
    }

    function isMinter(address minter_) public view returns (bool) {
        return _minters[minter_];
    }

    function setBaseURI(string calldata uri_) external onlyOwner {
        baseURI = uri_;
    }

    function tokenURI(uint256) public override(ERC721AUpgradeable) view returns (string memory) {
        return baseURI;
    } 

    function isApprovedForAll(address owner_, address operator_)
        public
        view
        virtual
        override(ERC721AUpgradeable)
        returns (bool)
    {
        return
            super.isApprovedForAll(owner_, operator_) ||
            OpenSeaGasFreeListing.isApprovedForAll(owner_, operator_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }
}