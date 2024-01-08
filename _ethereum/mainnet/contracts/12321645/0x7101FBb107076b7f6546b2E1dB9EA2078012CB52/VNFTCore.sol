// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./ERC721BurnableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./IVNFT.sol";
import "./AssetLibrary.sol";

abstract contract VNFTCore is IVNFT, ERC721Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AssetLibrary for AssetLibrary.Asset;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    event Mint(address indexed minter, uint256 indexed tokenId, uint256 indexed slot, uint256 units);
    event Burn(address indexed owner, uint256 indexed tokenId, uint256 units);

    struct ApproveUnits {
        bool isValid;
        mapping(address => uint256) approvals;
    }

    bytes4 private constant _VNFT_RECEIVED = 0xb382cdcd;

    //@dev The mapping of tokenId
    mapping(uint256 => AssetLibrary.Asset) public assets;

    //owner => tokenId => operator => units
    mapping (address => mapping(uint256 => ApproveUnits)) private _tokenApprovalUnits;

    //slot => tokenIds
    mapping (uint256 => EnumerableSetUpgradeable.UintSet) private _slotTokens;

    string private _contractURI;

    function _initialize(string memory name_, string memory symbol_, string memory baseURI_,
        string memory contractURI_)  internal {
        ERC721Upgradeable.__ERC721_init(name_, symbol_);
        ERC721Upgradeable._setBaseURI(baseURI_);
        _contractURI = contractURI_;
    }

    function _setContractURI(string memory uri_) internal {
        _contractURI = uri_;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _safeTransferUnitsFrom(address from_, address to_, uint256 tokenId_,
        uint256 targetTokenId_, uint256 transferUnits_, bytes memory data_) internal virtual {
        _transferUnitsFrom(from_, to_, tokenId_, targetTokenId_, transferUnits_);
        require(_checkOnVNFTReceived(from_, to_, targetTokenId_, transferUnits_, data_),
            "to non VNFTReceiver implementer");
    }

    function _transferUnitsFrom(address from_, address to_, uint256 tokenId_,
        uint256 targetTokenId_, uint256 transferUnits_) internal virtual {
        require(from_ == ownerOf(tokenId_), "VNFT: from not tokenId owner");

        //approve all后可不需要approve units
        if (_msgSender() != from_ && ! isApprovedForAll(from_, _msgSender())) {
            _tokenApprovalUnits[from_][tokenId_].approvals[_msgSender()] =
                _tokenApprovalUnits[from_][tokenId_].approvals[_msgSender()].sub(transferUnits_, "transfer units exceeds allowance");
        }

        require(to_ != address(0), "transfer to the address 0");

        if (! _exists(targetTokenId_)) {
            ERC721Upgradeable._mint(to_, targetTokenId_);
        } else {
            require(ownerOf(targetTokenId_) == to_, "to address not owner of target");
        }

        assets[tokenId_].transfer(assets[targetTokenId_], transferUnits_);

        emit PartialTransfer(from_, to_, tokenId_, targetTokenId_, transferUnits_);
    }

    function _merge(uint256 tokenId_, uint256 targetTokenId_) internal  virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "VNFT: not owner nor approved");
        require(_exists(targetTokenId_), "targetTokenId not exists");
        require(tokenId_ != targetTokenId_, "not same tokenId");

        address owner = ownerOf(tokenId_);
        require(owner == ownerOf(targetTokenId_), "source and target not same owner");

        uint256 mergeUnits = assets[tokenId_].merge(assets[targetTokenId_]);
        _burn(tokenId_);

        emit Merge(owner, tokenId_, targetTokenId_, mergeUnits);
    }

    function _splitUnits(uint256 tokenId_, uint256 newTokenId_, uint256 splitUnits_) internal  virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "VNFT: not owner nor approved");
        require(! _exists(newTokenId_), "VNFT: new token exists");

        assets[tokenId_].units = assets[tokenId_].units.sub(splitUnits_);

        address owner = ownerOf(tokenId_);
        _mintUnits(owner, newTokenId_, assets[tokenId_].slot, splitUnits_);

        emit Split(owner, tokenId_, newTokenId_, splitUnits_);
    }

    function approve(address to, uint256 tokenId, uint256 units) public virtual override {
        _approveUnits(_msgSender(), to, tokenId, units);
    }

    function _mintUnits(address minter_, uint256 tokenId_, uint256 slot_, uint256 units_) internal virtual {
        if (! _exists(tokenId_)) {
            ERC721Upgradeable._mint(minter_, tokenId_);
        }

        assets[tokenId_].mint(slot_, units_);
        if (! _slotTokens[slot_].contains(tokenId_)) {
            _slotTokens[slot_].add(tokenId_);
        }

        emit Mint(minter_, tokenId_, slot_, units_);
    }

    function _exists(uint256 tokenId_) internal view virtual override returns (bool) {
        return ERC721Upgradeable._exists(tokenId_);
    }

    function _burn(uint256 tokenId_) internal virtual override {
        uint256 units = assets[tokenId_].units;
        address owner = ownerOf(tokenId_);
        uint256 slot = assets[tokenId_].slot;
        if ( _slotTokens[slot].contains(tokenId_)) {
            _slotTokens[slot].remove(tokenId_);
        }
        delete assets[tokenId_];
        delete _tokenApprovalUnits[owner][tokenId_];
        ERC721Upgradeable._burn(tokenId_);
        emit Burn(owner, tokenId_, units);
    }

    function _burnUnits(uint256 tokenId_, uint256 burnUnits_) internal virtual returns (uint256 balance) {
        address owner = ownerOf(tokenId_);
        assets[tokenId_].burn(burnUnits_);
        
        emit Burn(owner, tokenId_, burnUnits_);

        return assets[tokenId_].units;
    }

    function _approveUnits(address owner, address to, uint256 tokenId, uint256 units) internal virtual {
        require(owner == ownerOf(tokenId), "VNFT: not owner");
        _tokenApprovalUnits[owner][tokenId].isValid = true;
        _tokenApprovalUnits[owner][tokenId].approvals[to] = units;
        emit ApprovalUnits(owner, to, tokenId, units);
    }

    function allowance(uint256 tokenId, address spender) public view virtual override returns (uint256) {
        address owner = ownerOf(tokenId);
        return _tokenApprovalUnits[owner][tokenId].approvals[spender];
    }

    function unitsInToken(uint256 tokenId_) public view virtual override  returns (uint256) {
        return assets[tokenId_].units;
    }

   function balanceOfSlot(uint256 slot) public view override returns (uint256) {
       return _slotTokens[slot].length();
   }
    function tokenOfSlotByIndex(uint256 slot, uint256 index) public view override returns (uint256) {
        return _slotTokens[slot].at(index);
    }

    function slotOf(uint256 tokenId_) override public view returns(uint256) {
        return assets[tokenId_].slot;
    }

    function isValid(uint256 tokenId_) public view returns (bool) {
        return assets[tokenId_].isValid;
    }

    function _checkOnVNFTReceived(address from_, address to_, uint256 tokenId_, uint256 units_,
        bytes memory _data) internal returns (bool)
    {
        if (!to_.isContract()) {
            return true;
        }
        bytes memory returndata = to_.functionCall(abi.encodeWithSelector(
                IVNFTReceiver(to_).onVNFTReceived.selector,
                _msgSender(),
                from_,
                tokenId_,
                units_,
                _data
            ), "non VNFTReceiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _VNFT_RECEIVED);
    }
}