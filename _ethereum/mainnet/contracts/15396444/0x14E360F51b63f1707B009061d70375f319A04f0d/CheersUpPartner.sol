// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ERC721A.sol"; 

/*
 ____                   _           _         
|  _ \                 | |         | |        
| |_) | __ _ ___  ___  | |     __ _| |__  ___ 
|  _ < / _` / __|/ _ \ | |    / _` | '_ \/ __|
| |_) | (_| \__ \  __/ | |___| (_| | |_) \__ \
|____/ \__,_|___/\___| |______\__,_|_.__/|___/
                                              
*/

pragma solidity ^0.8.7;

error ErrNoAddressProvided();
error ErrArrayLengthMismatch();
error ErrInvalidAddress();
error ErrTokenTransferPaused();
error ErrCallerIsContract();
error ErrContractSealed();
error ErrContractNotMintable();
error ErrContractNotBurnable();
error ErrContractNotModifiable();

/**
 * @title Sealable
 * @author BaseLabs
 */
contract Sealable {
    event ContractSealed();
    bool public contractSealed;
    /**
     * @notice when the project is stable enough, the issuer will call sealContract 
     * to give up the permission to call emergencyPause and unpause.
     */
    function _sealContract() internal {
        contractSealed = true;
        emit ContractSealed();
    }

    /***********************************|
    |             Modifier              |
    |__________________________________*/

    /**
     * @notice function call is only allowed when the contract has not been sealed
     */
    modifier notSealed() {
        if (contractSealed) revert ErrContractSealed();
        _;
    }
}

/**
 * @title AccessControl
 * @author BaseLabs
 */
contract AccessControl {
    event AccessControlConfigUpdated(AccessControlConfig);
    struct AccessControlConfig {
        bool mintable;
        bool burnable;
        bool modifiable;
    }
    AccessControlConfig public accessControlConfig = AccessControlConfig({
        mintable: true,
        burnable: true,
        modifiable: true
    });

    /**
     * @notice _setAccessConfig is used to control the operation permission of the contract
     * @param config_ access config
     */
    function _setAccessControlConfig(AccessControlConfig calldata config_) internal {
        accessControlConfig = config_;
        emit AccessControlConfigUpdated(config_);
    }

    /***********************************|
    |             Modifier              |
    |__________________________________*/

    /**
     * @notice decorator, function call is prohibited when mintable is false
     */
    modifier mintable() {
        if (!accessControlConfig.mintable) revert ErrContractNotMintable();
        _;
    }

    /**
     * @notice decorator, function call is prohibited when burnable is false
     */
    modifier burnable() {
        if (!accessControlConfig.burnable) revert ErrContractNotBurnable();
        _;
    }

    /**
     * @notice decorator, function call is prohibited when modifiable is false
     */
    modifier modifiable() {
        if (!accessControlConfig.modifiable) revert ErrContractNotModifiable();
        _;
    }
}

/**
 * @title CheersUpPartner
 * @author BaseLabs
 */
contract CheersUpPartner is ERC721A, Ownable, AccessControl, Sealable, Pausable, ReentrancyGuard {
    event URI(string value, uint256 indexed id);
    mapping(uint256 => string) private _uris;

    constructor() ERC721A("Cheers UP Partner", "CUPartner") {}

    /***********************************|
    |               Core                |
    |__________________________________*/

    /**
     * @notice giveaway is used for airdropping to specific addresses.
     * This process is under the supervision of the community.
     * @param addresses_ list of addresses to be airdropped.
     * @param uris_ the metadata uris corresponds to the addresses one-to-one.
     */
    function giveaway(address[] calldata addresses_, string[] calldata uris_) external onlyOwner mintable nonReentrant {
        if (addresses_.length != uris_.length) revert ErrArrayLengthMismatch();
        if (addresses_.length == 0) revert ErrNoAddressProvided();
        for (uint256 i = 0; i < addresses_.length; i++) {
            if (addresses_[i] == address(0)) revert ErrInvalidAddress();
            _setURI(_totalMinted(), uris_[i]);
            _safeMint(addresses_[i], 1);
        }
    }

    /**
     * @notice burn is used to destroy the token with the given ID
     * @param tokenId_ list of addresses to be airdropped.
     */
    function burn(uint256 tokenId_) external burnable nonReentrant {
        _burn(tokenId_, true);
    }

    /***********************************|
    |               Getter              |
    |__________________________________*/

    /**
     * @notice tokenURI is used to obtain the URI address corresponding to the tokenId
     * @param tokenId_ token id 
     * @return URI address corresponding to the tokenId
     */
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        if (!_exists(tokenId_)) revert URIQueryForNonexistentToken();
        return _uris[tokenId_];
    }

    /**
     * @notice totalMinted is used to return the total number of tokens minted. 
     * Note that it does not decrease as the token is burnt.
     */
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /***********************************|
    |               Setter              |
    |__________________________________*/

    /**
     * @notice setAccessControlConfig is used to control the operation permission of the contract
     * @param config_ access control config
     */
    function setAccessControlConfig(AccessControlConfig calldata config_) external onlyOwner notSealed {
        _setAccessControlConfig(config_);
    }

    /**
     * @notice when the project is stable enough, the issuer will call sealContract 
     * to give up the permission to call emergencyPause and unpause.
     */
    function sealContract() external onlyOwner notSealed {
        _sealContract();
    }

    /**
     * @notice setURI is used to set the URIs corresponding to the tokenIds
     * @param tokenIds_ list of token id
     * @param uris_ list of metadata uris corresponding to the token
     */
    function setURI(uint256[] calldata tokenIds_, string[] calldata uris_) external onlyOwner {
        unchecked {
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                _setURI(tokenIds_[i], uris_[i]);
            }
        }
    }

    /**
     * @notice setURI is used to set the URI corresponding to the tokenId
     * @param tokenId_ token id
     * @param uri_ metadata uri corresponding to the token
     */
    function _setURI(uint256 tokenId_, string calldata uri_) internal modifiable {
        _uris[tokenId_] = uri_;
        emit URI(uri_, tokenId_);
    }

    /***********************************|
    |               Pause               |
    |__________________________________*/

    /**
     * @notice hook function, used to intercept the transfer of token.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        if (paused()) revert ErrTokenTransferPaused();
    }

    /**
     * @notice for the purpose of protecting user assets, under extreme conditions, 
     * the circulation of all tokens in the contract needs to be frozen.
     * This process is under the supervision of the community.
     */
    function emergencyPause() external onlyOwner notSealed {
        _pause();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() external onlyOwner notSealed {
        _unpause();
    }
}
