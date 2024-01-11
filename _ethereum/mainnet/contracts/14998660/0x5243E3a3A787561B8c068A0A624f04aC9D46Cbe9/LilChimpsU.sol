// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Math.sol";
import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./AuthorizableU.sol";
import "./ERC721AU.sol";

error AlreadyAllMinted();
error AlreadyMintedAccount();
error NotStarted();
error NotInWhiteList();

contract LilChimpsU is AuthorizableU, ERC721AU, ReentrancyGuardUpgradeable {
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////
    uint256 public s_maxMintable;
    // metadata URI
    string public s_baseTokenURI;

    uint256 public s_startTimestamp;
    uint256 public s_preSaleDuration; // 4hours
    uint256 public s_preRevealDuration; // 24hours

    mapping(address => bool) public s_whiteList;

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////
    function initialize() public virtual initializer {
        __ERC721AU_init("Lil Chimps Official", "LILCHIMPSOFFICIAL");
        __Authorizable_init();
        __ReentrancyGuard_init();
        addAuthorized(_msgSender());

        s_maxMintable = 5555;
        s_preSaleDuration = 14400;  // 4 hours
        s_preRevealDuration = 86400;    // 1 day
        s_startTimestamp = block.timestamp + 31536000;
        s_baseTokenURI = "https://ipz.optimiz3.cloud/metadata/lilchimps/";
    }

    // util functions
    // function symbol() public view override returns (string memory) {
    //     return "LILCHIMPS";
    // }

    // Checking functions
    function isSaleStarted() public view returns (bool) {
        return block.timestamp > s_startTimestamp;
    }

    function isPresaleDuration() public view returns (bool) {
        return block.timestamp > s_startTimestamp && block.timestamp < s_startTimestamp + s_preSaleDuration;
    }

    function isPreRevealDuration() public view returns (bool) {
        return block.timestamp < s_startTimestamp || (block.timestamp > s_startTimestamp && block.timestamp < s_startTimestamp + s_preRevealDuration);
    }

    function isWhitelisted(address addr) public view returns (bool) {
        return s_whiteList[addr];
    }

    // Base URI ///////////////////////////////////////////////
    function _baseURI() internal view virtual override returns (string memory) {
        return s_baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyAuthorized {
        s_baseTokenURI = baseURI;
    }

    function setMaxMintable(uint256 _maxMintable) external onlyAuthorized {
        s_maxMintable = _maxMintable;
    }

    function setStartTimestamp(uint256 _startTimestamp) external onlyAuthorized {
        s_startTimestamp = _startTimestamp == 0 ? block.timestamp : _startTimestamp;
    }

    function setPreSaleDuration(uint256 _preSaleDuration) external onlyAuthorized {
        s_preSaleDuration = _preSaleDuration;
    }

    function setPreRevealDuration(uint256 _preRevealDuration) external onlyAuthorized {
        s_preRevealDuration = _preRevealDuration;
    }

    function addWhitelist(address[] memory addresses) external onlyAuthorized {
        for (uint256 i = 0; i < addresses.length; i++) {
            s_whiteList[addresses[i]] = true;
        }
    }

    function removeWhitelist(address[] memory addresses) external onlyAuthorized {
        for (uint256 i = 0; i < addresses.length; i++) {
            s_whiteList[addresses[i]] = false;
        }
    }    

    function adminMint(address[] memory recipients, uint256[] memory quantities) public onlyAuthorized {
        if (_totalMinted() == s_maxMintable) {
            revert AlreadyAllMinted();
        }
        
        for (uint i=0; i<recipients.length; i++) {
            uint256 remainedTokens = s_maxMintable - _totalMinted();
            uint256 mintAmount = Math.min(remainedTokens, quantities[i]);
            _safeMint(recipients[i], mintAmount);
        }
    }

    function mint() external payable callerIsUser {
        if (_totalMinted() == s_maxMintable) {
            revert AlreadyAllMinted();
        }
        if (_numberMinted(msg.sender) > 0) {
            revert AlreadyMintedAccount();
        }
        if (block.timestamp < s_startTimestamp) {
            revert NotStarted();
        }
        if (block.timestamp < s_startTimestamp + s_preSaleDuration) {
            if (!s_whiteList[msg.sender]) {
                revert NotInWhiteList();
            }
        }
        _safeMint(msg.sender, 1);
    }

    /////////////////////////////////////////////////

    function withdrawFund() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }
}
