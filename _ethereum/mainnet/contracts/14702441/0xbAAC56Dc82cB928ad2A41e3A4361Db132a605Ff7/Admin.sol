// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

import "./IAllowlist.sol";
import "./IRoyalty.sol";
import "./Base.sol";
import "./IAdmin.sol";
import "./IConfig.sol";

contract Admin is
    Base,
    IAdmin,
    IConfig {

    // TODO: add abi uri
    constructor ()  {}

    IConfig.Config[] public config;
    IConfig.Pricelist[] public pricelists;

    address payable public splitContract;

    mapping(uint256 => uint256) public allocations;
    mapping(IConfig.Extensions => address) public extensions;

    // see https://docs.opensea.io/docs/contract-level-metadata
    string private _contractURI;

    /**
     * @dev see {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, Base) returns (bool) {
        return interfaceId == type(IAdmin).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
    * @dev see {IAdmin-createConfig}
    */
    function createConfig(IConfig.Config memory _config) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        config.push(_config);
    }

    /**
    * @dev see {IAdmin-updateConfig}
    */
    function updateConfig(uint256 _configId, IConfig.Config memory _config) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        if (config.length == 0) revert ConfigNotFound(_configId);
        if (!(config.length > _configId)) revert ConfigNotFound(_configId);
        config[_configId].mintConfig = _config.mintConfig;
        config[_configId].tokenConfig = _config.tokenConfig;
    }

    /**
    * @dev see {IAdmin-getAllocationByAddress}
    */
    function getAllocationByAddress(address _address, bytes32[][] memory _proofs) public view returns (Allocation memory) {
        (bool exists, uint256 allowlistId) = getAllowlistIdByAddress(_address, _proofs);
        uint256 allocated = 0;
        uint256 price = 0;
        if (exists) {
            allocated = allocations[allowlistId];
            price = getPricelistByAllowlistId(allowlistId).price;
        }
        return Allocation(allowlistId, allocated, price);
    }

    /**
    * @dev see {IAdmin-getAllocationTotalByAddress}
    */
    function getAllocationTotalByAddress(address _address, bytes32[][] memory _proofs) public view returns (uint256) {
        IAllowlist.Allowlist[] memory allowlists = IAllowlist(extensions[IConfig.Extensions.Allowlist]).getAllowlists();
        uint256 allocated = 0;
        unchecked {
            for (uint i = 0; i < allowlists.length; i++) {
                if (IAllowlist(extensions[IConfig.Extensions.Allowlist]).isAllowedOn(i, _address, _proofs)) allocated += allocations[i];
            }
        }
        return allocated;
    }

    /**
    * @dev see {IAdmin-getAllowlistIdByAddress}
    */
    function getAllowlistIdByAddress(address _address, bytes32[][] memory _proofs) public view returns (bool, uint256) {
        IAllowlist.Allowlist[] memory allowlists = IAllowlist(extensions[IConfig.Extensions.Allowlist]).getAllowlists();
        unchecked {
            for (uint i = 0; i < allowlists.length; i++) {
                if (IAllowlist(extensions[IConfig.Extensions.Allowlist]).isAllowedOn(i, _address, _proofs)) return (true, i);
            }
        }
        return (false, 0);
    }

    /**
    * @dev see {IAdmin-setAllocation}
    */
    function setAllocation(uint256 _allowlistId, uint256 _allocation) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        allocations[_allowlistId]= _allocation;
    }

    /**
    * @dev see {IAdmin-setContractURI}
    */
    function setContractURI(string memory contractURI_) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        _contractURI = contractURI_;
    }

    /**
    * @dev see {IAdmin-getContractURI}
    */
    function getContractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
    * @dev see {IAdmin-setExtensions}
    */
    function setExtension(IConfig.Extensions _extension, address _address) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        // check whether or not _address supports the proper interface before setting extension address
        if (_extension == IConfig.Extensions.Allowlist) {
            if (!IAllowlist(_address).supportsInterface(type(IAllowlist).interfaceId)) revert ExtensionInvalid();
        } else if (_extension == IConfig.Extensions.Royalty) {
            if (!IRoyalty(_address).supportsInterface(type(IRoyalty).interfaceId)) revert ExtensionInvalid();
        }
        else {
            revert ExtensionInvalid();
        }
        extensions[_extension] = _address;
    }

    /**
    * @dev see {IAdmin-createPricelist}
    */
    function createPricelist(IConfig.Pricelist memory _pricelist) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        pricelists.push(_pricelist);
    }

    /**
    * @dev see {IAdmin-updatePricelist}
    */
    function updatePricelist(uint256 _pricelistId, IConfig.Pricelist memory _pricelist) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        if (pricelists.length == 0) revert PricelistNotFound(_pricelistId);
        if (!(pricelists.length > _pricelistId)) revert PricelistNotFound(_pricelistId);
        pricelists[_pricelistId] = _pricelist;
    }

    /**
    * @dev see {IAdmin-updatePricelistByAllowlistId}
    */
    function updatePricelistByAllowlistId(uint256 _allowlistId, IConfig.Pricelist memory _pricelist) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
      unchecked {
          for (uint i = 0; i < pricelists.length; i++) {
              if (pricelists[i].allowlistId == _allowlistId) pricelists[i] = _pricelist;
          }
      }
    }

    /**
    * @dev see {IAdmin-getPricelistByAllowlistId}
    */
    function getPricelistByAllowlistId(uint256 _allowlistId) public view returns (IConfig.Pricelist memory) {
        unchecked {
            for (uint i = 0; i < pricelists.length; i++) {
                if (pricelists[i].allowlistId == _allowlistId) return pricelists[i];
            }
        }
        revert PricelistNotFound(_allowlistId);
    }

    /**
    * @dev see {IAdmin-setSplitContract}
    */
    function setSplitContract(address payable _address) external onlyRole(CONTRACT_ADMIN_ROLE) {
        splitContract = _address;
    }

    /**
    * @dev see {IAdmin-getSplitContract}
    */
    function getSplitContract() external view returns (address payable) {
        return splitContract;
    }

    /**
    * @dev see {IAdmin-createAllowlist}
    */
    function createAllowlist(IAllowlist.Allowlist memory _allowlist) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        IAllowlist(extensions[IConfig.Extensions.Allowlist]).createAllowlist(_allowlist);
    }

    /**
    * @dev see {IAdmin-updateAllowlist}
    */
    function updateAllowlist(uint256 _allowlistId, IAllowlist.Allowlist memory _allowlist) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        IAllowlist(extensions[IConfig.Extensions.Allowlist]).updateAllowlist(_allowlistId, _allowlist);
    }

    /**
    * @dev see {IAdmin-getAllowlists}
    */
    function getAllowlists() external view returns (IAllowlist.Allowlist[] memory) {
      IAllowlist.Allowlist[] memory allowlists = IAllowlist(extensions[IConfig.Extensions.Allowlist]).getAllowlists();
      return allowlists;
    }

    /**
    * @dev {IAdmin-addRoyaltyShare}
    */
    function addRoyaltyShare(address _account) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        IRoyalty(extensions[IConfig.Extensions.Royalty]).addShare(_account);
    }

    /**
    * @dev {IAdmin-removeRoyaltyShare}
    */
    function removeRoyaltyShare(address _account) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        IRoyalty(extensions[IConfig.Extensions.Royalty]).removeShare(_account);
    }

    /**
    * @dev see {IAdmin-revertOnAllocationCheckFailure}
    */
    function revertOnAllocationCheckFailure(address _address, bytes32[][] memory _proofs, uint256 _quantity) external view returns (Allocation memory) {
        return _revertOnAllocationCheckFailure(_address, _proofs, _quantity);
    }

    /**
    * @dev see {IAdmin-revertOnMintCheckFailure}
    */
    function revertOnMintCheckFailure(uint256 _configId, uint256 _quantity, uint256 _totalSupply, bool _paused) external view {
        _revertOnMintCheckFailure(_configId, _quantity, _totalSupply, _paused);
    }

    /**
    * @dev see {IAdmin-revertOnAllocationCheckFailure}
    */
    function _revertOnAllocationCheckFailure(address _address, bytes32[][] memory _proofs, uint256 _quantity) internal view returns (Allocation memory) {
        Allocation memory allocated = getAllocationByAddress(_address, _proofs);
        if (_quantity > allocated.allocation) revert AllocationExceeded();
        return allocated;
    }

    /**
    * @dev see {IAdmin-revertOnPaymentFailure}
    */
    function revertOnPaymentFailure(uint256 _configId, uint256 _price, uint256 _quantity, uint256 _payment, bool _override) external view {
        _revertOnPaymentFailure(_configId, _price, _quantity, _payment, _override);
    }

    /**
    * @dev see {IAdmin-revertOnArbitraryPaymentFailure}
    */
    function revertOnArbitraryPaymentFailure(uint256 _price, uint256 _payment) external pure {
        if (_payment < _price) revert InsufficientFunds();
    }

    /**
    * @dev see {IAdmin-revertOnMintCheckFailure}
    */
    function _revertOnMintCheckFailure(
        uint256 _configId,
        uint256 _quantity,
        uint256 _totalSupply,
        bool _paused
    ) internal view {
        if (config.length == 0) revert ConfigNotFound(_configId);
        if (!(config.length > _configId)) revert ConfigNotFound(_configId);
        if (_paused) revert MintPaused();
        if (!config[_configId].mintConfig.isActive) revert MintInactive();
        if (block.timestamp < config[_configId].mintConfig.startTime) revert MintNotStarted();
        if (block.timestamp > config[_configId].mintConfig.endTime) revert MintClosed();
        if (_quantity == 0) revert MintQuantityInvalid();
        if (_quantity > config[_configId].mintConfig.maxPerTxn) revert MintQuantityPerTxnExceeded();
        if (_totalSupply + _quantity > config[_configId].mintConfig.maxSupply) revert MintQuantityExceedsMaxSupply();
    }

    /**
    * @dev see {IAdmin-revertOnArbitraryAllocationCheckFailure}
    */
    function revertOnArbitraryAllocationCheckFailure(address _address, uint256 _numMinted, uint256 _quantity, bytes32[] calldata _proof, uint256 _allowlistID, uint256 _allowed) external view {
        _revertOnArbitraryAllocationCheckFailure(_address,_numMinted, _quantity, _proof, _allowlistID, _allowed);
    }

    /**
    * @dev see {IAdmin-revertOnMintCheckFailure}
    */
    function _revertOnArbitraryAllocationCheckFailure(
        address _address,
        uint256 _numMinted,
        uint256 _quantity,
        bytes32[] calldata _proof,
        uint256 _allowlistID,
        uint256 _allowed
    ) internal view {

        //if allowlist exists, does merkle proof validate
         IAllowlist.Allowlist memory allowlist = IAllowlist(extensions[IConfig.Extensions.Allowlist]).getAllowlist(_allowlistID);
         if(allowlist.isActive && allowlist.typedata != '0x' && allowlist.typedata != 0x1e0fa23b9aeab82ec0dd34d09000e75c6fd16dccda9c8d2694ecd4f190213f45 && allowlist.typedata != 0x0000000000000000000000000000000000000000000000000000000000000000){
             if (_quantity > _allowed) revert ArbitraryAllocationExceeded();
             if ((_quantity + _numMinted) > _allowed) revert IAdmin.AllocationExceeded();
             if (!IAllowlist(extensions[IConfig.Extensions.Allowlist]).isAllowedArbitrary(_address, _proof, allowlist, _allowed)) revert ArbitraryAllocationVerificationError();
         }
         else if(!allowlist.isActive){
              revert ArbitraryAllocationVerificationError();
         }

    }

    /**
    * @dev see {IAdmin-revertOnTotalAllocationCheckFailure}
    */
    function revertOnTotalAllocationCheckFailure(uint256 _totalMinted, uint256 _quantity, uint256 _allowed) external view {
        if(_totalMinted + _quantity > _allowed) revert ArbitraryTotalAllocationExceeded();
    }

    /**
    * @dev see {IAdmin-revertOnMaxWalletMintCheckFailure}
    */
    function revertOnMaxWalletMintCheckFailure(uint256 _configId, uint256 _quantity, uint256 _totalMinted) external view {
        if (_totalMinted + _quantity > config[_configId].mintConfig.maxPerWallet) revert MintQuantityPerWalletExceeded();
    }

    /**
    * @dev see {IAdmin-revertOnPaymentFailure}
    */
    function _revertOnPaymentFailure(
        uint256 _configId,
        uint256 _price,
        uint256 _quantity,
        uint256 _payment,
        bool _override
    ) internal view {
        if (config.length == 0) revert ConfigNotFound(_configId);
        if (!(config.length > _configId)) revert ConfigNotFound(_configId);
        // use _price instead of mintConfig.price if _override
        if (_override) {
            if (_payment < (_price * _quantity)) revert InsufficientFunds();
            if (_payment > (_price * _quantity)) revert ExcessiveFunds();
        } else {
            if (_payment < (config[_configId].mintConfig.price * _quantity)) revert InsufficientFunds();
            if (_payment > (config[_configId].mintConfig.price * _quantity)) revert ExcessiveFunds();
        }
    }

}
