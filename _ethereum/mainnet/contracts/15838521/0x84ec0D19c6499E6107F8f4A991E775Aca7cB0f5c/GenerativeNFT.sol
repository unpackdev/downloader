// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./ERC721PresetMinterPauserAutoId.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./IERC2981.sol";
import "./Random.sol";
import "./Errors.sol";
import "./BoilerplateParam.sol";
import "./TraitInfo.sol";
import "./IGenerativeNFT.sol";
import "./IGenerativeBoilerplateNFT.sol";

contract GenerativeNFT is ERC721PresetMinterPauserAutoId, ReentrancyGuard, IERC2981, IGenerativeNFT, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    // admin of collection -> owner, creator, ...
    address public _admin;
    // linked boilerplate address
    address public _boilerplateAddr;
    // linked projectId in boilerplate
    uint256 public _boilerplateId;
    // params value for rendering -> mapping with tokenId of NFT
    mapping(uint256 => BoilerplateParam.ParamsOfProject) public _paramsValues;

    TraitInfo.Traits private _traits;

    // 
    mapping(uint256 => string) _customUri;
    // creator of nft tokenID, set from boilerplate calling
    mapping(uint256 => address) public _creators;

    string private _nameColl;
    string private _symbolColl;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseuri,
        address admin
    ) ERC721PresetMinterPauserAutoId(_name, _symbol, _baseuri) {
        _admin = admin;
    }

    function owner() public view override returns (address) {
        return _admin;
    }

    function _checkOwner() internal view override {
        require(owner() == msg.sender || msg.sender == _boilerplateAddr, "Ownable: caller is not the owner");
    }

    function initAdmin(address _newAdmin) internal {
        require(msg.sender == _boilerplateAddr, "INV_SENDER_INIT_ADMIN");
        require(_newAdmin != address(0x0), "INV_ADD");

        _admin = _newAdmin;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MINTER_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
    }

    function init(
        string memory name,
        string memory symbol,
        address admin,
        address boilerplateAdd,
        uint256 boilerplateId
    ) external {
        require(boilerplateAdd != address(0x0), "INV_ADD");
        require(admin != address(0x0), "INV_ADD");
        require(_boilerplateId == 0, "EXISTED");

        _nameColl = name;
        _symbolColl = symbol;
        _boilerplateAddr = boilerplateAdd;
        _boilerplateId = boilerplateId;
        initAdmin(admin);
        transferOwnership(admin);
    }

    function updateTraits(TraitInfo.Traits calldata traits) external {
        require(msg.sender == _admin || msg.sender == _boilerplateAddr, Errors.ONLY_ADMIN_ALLOWED);
        _traits = traits;
    }

    function getTraits() public view returns (TraitInfo.Trait[] memory){
        return _traits._traits;
    }


    function getTokenTraits(uint256 tokenId) public view returns (TraitInfo.Trait[] memory){
        BoilerplateParam.ParamsOfProject memory p = _paramsValues[tokenId];
        TraitInfo.Trait[] memory result = _traits._traits;
        if (result.length != p._params.length) {
            return result;
        }
        for (uint8 i = 0; i < p._params.length; i++) {
            uint256 val = p._params[i]._value;
            if (result[i]._availableValues.length > 0) {
                result[i]._valueStr = result[i]._availableValues[val];
                result[i]._value = val;
            } else {
                result[i]._value = val;
            }
        }
        return result;
    }

    function name() public view override returns (string memory) {
        return _nameColl;
    }

    function symbol() public view override returns (string memory) {
        return _symbolColl;
    }

    modifier creatorOnly(uint256 _id) {
        require(_creators[_id] == _msgSender(), "ONLY_CREATOR");
        _;
    }

    modifier adminOnly() {
        require(_msgSender() == _admin, "ONLY_ADMIN_ALLOWED");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ONLY_ADMIN_ALLOWED");
        _;
    }

    function changeAdmin(address _newAdmin) public adminOnly {
        require(_newAdmin != address(0), Errors.INV_ADD);
        address _previousAdmin = _admin;
        _admin = _newAdmin;

        grantRole(DEFAULT_ADMIN_ROLE, _admin);
        grantRole(MINTER_ROLE, _admin);
        grantRole(PAUSER_ROLE, _admin);

        revokeRole(DEFAULT_ADMIN_ROLE, _previousAdmin);
        revokeRole(MINTER_ROLE, _previousAdmin);
        revokeRole(PAUSER_ROLE, _previousAdmin);
    }

    function mint(address to) public override {}

    function mint(address mintTo, address creator, string memory uri, BoilerplateParam.ParamsOfProject calldata _paramsTemplateValue) external {
        require(msg.sender == _boilerplateAddr, Errors.INV_BOILERPLATE_ADD);
        require(_boilerplateAddr != address(0) && _boilerplateId > 0, Errors.INV_PROJECT);

        // verify seed
        bytes32 seed = _paramsTemplateValue._seed;
        for (uint256 i = 0; i < _paramsTemplateValue._params.length; i++) {
            BoilerplateParam.ParamTemplate memory param = _paramsTemplateValue._params[i];
            if (!param._editable) {
                if (param._availableValues.length == 0) {
                    require(Random.randomValueRange(uint256(seed), param._min, param._max) == param._value, Errors.SEED_INV_1);
                } else {
                    require(Random.randomValueIndexArray(uint256(seed), param._availableValues.length) == param._value, Errors.SEED_INV_2);
                }
            }
            seed = keccak256(abi.encodePacked(seed, param._value));
        }

        IGenerativeBoilerplateNFT boilerplateNFT = IGenerativeBoilerplateNFT(_boilerplateAddr);
        require(boilerplateNFT.exists(_boilerplateId), Errors.INV_PROJECT);

        _nextTokenId.increment();
        uint256 currentTokenId = _nextTokenId.current();
        if (bytes(uri).length > 0) {
            _customUri[currentTokenId] = uri;
        }
        _creators[currentTokenId] = creator;
        _paramsValues[currentTokenId] = _paramsTemplateValue;
        _safeMint(mintTo, currentTokenId);

        emit MintGenerativeNFT(mintTo, creator, uri, currentTokenId);
    }

    function _setCreator(address _to, uint256 _id) internal creatorOnly(_id)
    {
        _creators[_id] = _to;
    }

    function setCreator(
        address _to,
        uint256[] memory _ids
    ) public {
        require(_to != address(0), Errors.INV_ADD);

        _grantRole(MINTER_ROLE, _to);
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            _setCreator(_to, id);
        }
    }

    function getParamValues(uint256 tokenId) public view returns (bytes32, BoilerplateParam.ParamTemplate[] memory) {
        return (_paramsValues[tokenId]._seed, _paramsValues[tokenId]._params);
    }

    function totalSupply() public view override returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _baseURI();
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        bytes memory customUriBytes = bytes(_customUri[_tokenId]);
        if (customUriBytes.length > 0) {
            return _customUri[_tokenId];
        } else {
            return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
        }
    }

    function setCustomURI(
        uint256 _tokenId,
        string memory _newURI
    ) public creatorOnly(_tokenId) {
        _customUri[_tokenId] = _newURI;
    }

    /** @dev EIP2981 royalties implementation. */
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
        bool isValue;
    }

    mapping(uint256 => RoyaltyInfo) public royalties;

    function setTokenRoyalty(
        uint256 _tokenId,
        address _recipient,
        uint256 _value
    ) public adminOnly {
        require(_value <= 10000, Errors.REACH_MAX);
        royalties[_tokenId] = RoyaltyInfo(_recipient, uint24(_value), true);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalty = royalties[_tokenId];
        if (royalty.isValue) {
            receiver = royalty.recipient;
            royaltyAmount = (_salePrice * royalty.amount) / 10000;
        } else {
            receiver = _creators[_tokenId];
            royaltyAmount = (_salePrice * 500) / 10000;
        }
    }
}
