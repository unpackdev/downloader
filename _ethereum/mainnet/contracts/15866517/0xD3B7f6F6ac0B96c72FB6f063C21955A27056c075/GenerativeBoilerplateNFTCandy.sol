// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ClonesUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./Errors.sol";
import "./GenerativeBoilerplateNFTConfiguration.sol";
import "./Random.sol";
import "./BoilerplateParam.sol";
import "./StringUtils.sol";
import "./IGenerativeBoilerplateNFT.sol";
import "./IGenerativeNFT.sol";
import "./IParameterControl.sol";
import "./TraitInfo.sol";

contract GenerativeBoilerplateNFTCandy is Initializable, ERC721PresetMinterPauserAutoIdUpgradeable, ReentrancyGuardUpgradeable, IERC2981Upgradeable, IGenerativeBoilerplateNFT {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using ClonesUpgradeable for *;
    using SafeMathUpgradeable for uint256;

    // super admin
    address public _admin;
    // parameter control address
    address public _paramsAddress;

    // projectId is tokenID of project nft
    CountersUpgradeable.Counter private _nextProjectId;
    CountersUpgradeable.Counter private _nextTokenId;

    struct ProjectInfo {
        uint256 _fee; // default frees
        address _feeToken;// default is native token
        uint256 _mintMaxSupply; // max supply can be minted on project
        uint256 _mintTotalSupply; // total supply minted on project
        BoilerplateParam.ParamsOfProject _paramsTemplate; // struct contains list params of project and random seed(registered) in case mint nft from project
        uint256 _mintNotOwnerProjectMaxSupply; // limit for nminter is not owner of project
        uint256 _mintNotOnwerProjectTotalSupply;
    }

    mapping(uint256 => ProjectInfo) public _projects;

    // params value for rendering -> mapping with tokenId of NFT
    mapping(uint256 => BoilerplateParam.ParamsOfNFT) public _paramsValues;

    TraitInfo.Traits private _traits;

    mapping(uint256 => string) _customUri;
    // creator of nft tokenID, set from boilerplate calling
    mapping(uint256 => address) public _creators;


    function initialize(
        string memory name,
        string memory symbol,
        string memory baseUri,
        address admin,
        address paramsAddress
    ) initializer public {
        require(admin != address(0), Errors.INV_ADD);
        require(paramsAddress != address(0), Errors.INV_ADD);
        __ERC721PresetMinterPauserAutoId_init(name, symbol, baseUri);
        _paramsAddress = paramsAddress;
        _admin = admin;
        // set role for admin address
        grantRole(DEFAULT_ADMIN_ROLE, _admin);

        // revoke role for sender
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function updateTraits(TraitInfo.Traits calldata traits) external {
        //        require(msg.sender == _admin || msg.sender == _boilerplateAddr, Errors.ONLY_ADMIN_ALLOWED);
        require(msg.sender == _admin);
        _traits = traits;
    }

    function getTraits() public view returns (TraitInfo.Trait[] memory){
        return _traits._traits;
    }

    function getTokenTraits(uint256 tokenId) public view returns (TraitInfo.Trait[] memory){
        (bytes32 seed, BoilerplateParam.ParamTemplate[] memory _params) = getParamValues(tokenId);

        TraitInfo.Trait[] memory result = _traits._traits;
        if (result.length != _params.length) {
            return result;
        }
        for (uint8 i = 0; i < _params.length; i++) {
            uint256 val = _params[i]._value;
            if (result[i]._availableValues.length > 0) {
                result[i]._valueStr = result[i]._availableValues[val];
                result[i]._value = val;
            } else {
                result[i]._value = val;
            }
        }
        return result;
    }

    function getParamValues(uint256 tokenId) public view returns (bytes32, BoilerplateParam.ParamTemplate[] memory) {
        BoilerplateParam.ParamsOfNFT memory pNFT = _paramsValues[tokenId];
        bytes32 seed = pNFT._seed;

        //        IGenerativeBoilerplateNFT b = IGenerativeBoilerplateNFT(_boilerplateAddr);
        //        BoilerplateParam.ParamsOfProject memory p = b.getParamsTemplate(_boilerplateId);

        BoilerplateParam.ParamsOfProject memory p = _projects[1]._paramsTemplate;
        for (uint256 i = 0; i < p._params.length; i++) {
            if (!p._params[i]._editable) {
                if (p._params[i]._availableValues.length == 0) {
                    p._params[i]._value = Random.randomValueRange(uint256(seed), p._params[i]._min, p._params[i]._max);
                } else {
                    p._params[i]._value = Random.randomValueIndexArray(uint256(seed), p._params[i]._availableValues.length);
                }
            } else {
                p._params[i]._value = pNFT._value[i];
            }
            seed = keccak256(abi.encodePacked(seed, p._params[i]._value));
        }
        return (pNFT._seed, p._params);
    }

    function changeAdmin(address newAdm, address newParam) external {
        require(msg.sender == _admin && hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) && newAdm != address(0), Errors.ONLY_ADMIN_ALLOWED);

        // change admin
        if (_admin != newAdm) {
            address _previousAdmin = _admin;
            _admin = newAdm;
            grantRole(DEFAULT_ADMIN_ROLE, _admin);
            revokeRole(DEFAULT_ADMIN_ROLE, _previousAdmin);
        }

        // change param
        require(newParam != address(0));
        if (_paramsAddress != newParam) {
            _paramsAddress = newParam;
        }
    }

    // disable old mint
    function mint(address to) public override {}
    // disable pause
    function pause() public override {}
    // disable unpause
    function unpause() public override {}

    // disable burn
    function burn(uint256 tokenId) public override {}

    // mint a Project token id
    // to: owner
    // name: name of project
    // maxSupply: max available nft supply which minted from this project
    // uri: metadata of project info
    // fee: fee mint nft from this project
    // feeAdd: currency for mint nft fee
    // paramsTemplate: json format string for render view template
    function mintProject(
        address to,
        uint256 maxSupply,
        uint256 maxNotOwner,
        uint256 fee,
        address feeAdd,
        BoilerplateParam.ParamsOfProject calldata paramsTemplate
    ) external nonReentrant payable returns (uint256) {
        require(msg.sender == _admin);

        _nextProjectId.increment();
        uint256 currentTokenId = _nextProjectId.current();
        require(_projects[currentTokenId]._paramsTemplate._params.length == 0, Errors.INV_PROJECT);

        _projects[currentTokenId]._mintMaxSupply = maxSupply;
        _projects[currentTokenId]._mintNotOwnerProjectMaxSupply = maxNotOwner;
        _projects[currentTokenId]._fee = fee;
        _projects[currentTokenId]._feeToken = feeAdd;
        _projects[currentTokenId]._paramsTemplate = paramsTemplate;

        return currentTokenId;
    }

    function updateProject(uint256 projectId,
        uint256 newFee, address newFeeAddr,
        string memory newScript,
        address newMinterNFTInfo,
        uint256 maxSupply,
        uint256 totalSupply,
        uint256 notOwnerMaxSupply,
        uint256 notOwnerTotalSupply
    ) external {
        require(msg.sender == _admin, Errors.ONLY_CREATOR);
        _projects[projectId]._fee = newFee;
        _projects[projectId]._feeToken = newFeeAddr;
        _projects[projectId]._mintMaxSupply = maxSupply;
        _projects[projectId]._mintTotalSupply = totalSupply;
        _projects[projectId]._mintNotOwnerProjectMaxSupply = notOwnerMaxSupply;
        _projects[projectId]._mintNotOnwerProjectTotalSupply = notOwnerTotalSupply;
    }

    // mintBatchUniqueNFT
    // from projectId -> get algo and minting an batch unique nfr on GenerativeNFT contract collection
    // by default, contract should get 5% fee when minter pay for owner of project
    function mintBatchUniqueNFT(MintRequest memory mintBatch) public nonReentrant payable {
        ProjectInfo memory project = _projects[mintBatch._fromProjectId];
        require(mintBatch._paramsBatch.length > 0 && mintBatch._uriBatch.length == mintBatch._paramsBatch.length, Errors.INV_PARAMS);
        require(project._mintMaxSupply == 0 || project._mintTotalSupply + mintBatch._paramsBatch.length <= project._mintMaxSupply, Errors.REACH_MAX);
        if (project._mintNotOwnerProjectMaxSupply > 0) {// not owner of project
            if (msg.sender != _admin) {
                _projects[mintBatch._fromProjectId]._mintNotOnwerProjectTotalSupply += mintBatch._paramsBatch.length;
                require(_projects[mintBatch._fromProjectId]._mintNotOnwerProjectTotalSupply <= project._mintNotOwnerProjectMaxSupply);
            }
        }
        // get payable
        uint256 _mintFee = project._fee;
        IParameterControl _p = IParameterControl(_paramsAddress);
        if (_mintFee > 0) {// has fee and
            if (msg.sender != _admin) {// not owner of project -> get payment
                _mintFee *= mintBatch._paramsBatch.length;
                uint256 operationFee = _p.getUInt256(GenerativeBoilerplateNFTConfiguration.MINT_NFT_FEE);
                if (operationFee == 0) {
                    operationFee = 500;
                    // default 5% getting, 95% pay for owner of project
                }
                if (project._feeToken == address(0x0)) {
                    require(msg.value >= _mintFee);

                    // pay for owner project
                    (bool success,) = ownerOf(mintBatch._fromProjectId).call{value : _mintFee - (_mintFee * operationFee / 10000)}("");
                    require(success);
                } else {
                    IERC20Upgradeable tokenERC20 = IERC20Upgradeable(project._feeToken);
                    // transfer all fee erc-20 token to this contract
                    require(tokenERC20.transferFrom(
                            msg.sender,
                            address(this),
                            _mintFee
                        ));

                    // pay for owner project
                    require(tokenERC20.transfer(ownerOf(mintBatch._fromProjectId), _mintFee - (_mintFee * operationFee / 10000)));
                }
            }
        }

        // minting NFT to other collection by minter
        // needing deploy an new one by cloning from GenerativeNFT(ERC-721) template when mint project
        // get generative nft collection template
        //        IGenerativeNFT nft = IGenerativeNFT(_projects[mintBatch._fromProjectId]._minterNFTInfo);
        for (uint256 i = 0; i < mintBatch._paramsBatch.length; i++) {
            require(_projects[mintBatch._fromProjectId]._paramsTemplate._params.length == mintBatch._paramsBatch[i]._value.length, Errors.INV_PARAMS);

            // verify seed
            bytes32 seed;
            // TODO
            mintBatch._paramsBatch[i]._seed = Random.randomSeed(msg.sender, mintBatch._fromProjectId, project._mintTotalSupply + 1);
            seed = mintBatch._paramsBatch[i]._seed;
            // check token uri
            string memory uri = mintBatch._uriBatch[i];
            if (bytes(uri).length == 0) {
                // lazy render
                uri = string(
                    abi.encodePacked(
                        _p.get(GenerativeBoilerplateNFTConfiguration.NFT_BASE_URI),
                        StringsUpgradeable.toHexString(uint256(uint160(address(this))), 20),
                        GenerativeBoilerplateNFTConfiguration.SEPERATE_URI,
                        StringsUpgradeable.toString(mintBatch._fromProjectId),
                        GenerativeBoilerplateNFTConfiguration.SEPERATE_URI,
                        StringsUpgradeable.toString(project._mintTotalSupply + 1)
                    )
                );
            }
            mintNFT(mintBatch._fromProjectId, mintBatch._mintTo, _admin, uri, mintBatch._paramsBatch[i]);
            // increase total supply minting on project
            project._mintTotalSupply += 1;
            _projects[mintBatch._fromProjectId]._mintTotalSupply = project._mintTotalSupply;
            // marked this seed is already used
        }
    }

    function mintNFT(uint256 projectId, address mintTo, address creator, string memory uri, BoilerplateParam.ParamsOfNFT memory _paramsTemplateValue) internal {
        require(_projects[projectId]._paramsTemplate._params.length != 0, Errors.INV_PROJECT);

        _nextTokenId.increment();
        uint256 currentTokenId = _nextTokenId.current();
        if (bytes(uri).length > 0) {
            _customUri[currentTokenId] = uri;
        }
        _creators[currentTokenId] = _admin;
        _paramsValues[currentTokenId] = _paramsTemplateValue;
        _safeMint(mintTo, currentTokenId);
    }

    // setCreator
    // func for set new creator on projectId
    // only creator on projectId can make this func
    function setCreator(address _to, uint256 _id) external {
        require(_creators[_id] == msg.sender, Errors.ONLY_CREATOR);
        _creators[_id] = _to;
    }

    function totalSupply() public view override returns (uint256) {
        return _nextTokenId.current();
    }


    function baseTokenURI() virtual public view returns (string memory) {
        return _baseURI();
    }

    function setCustomURI(
        uint256 _tokenId,
        string memory _newURI
    ) public {
        require(msg.sender == _creators[_tokenId], Errors.ONLY_CREATOR);
        _customUri[_tokenId] = _newURI;
    }

    // tokenURI
    // return URI data of project
    // base on customUri of project of baseUri of erc-721
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        bytes memory customUriBytes = bytes(_customUri[_tokenId]);
        if (customUriBytes.length > 0) {
            return _customUri[_tokenId];
        } else {
            return string(abi.encodePacked(baseTokenURI(), StringsUpgradeable.toString(_tokenId)));
        }
    }

    function exists(
        uint256 _id
    ) external view returns (bool) {
        return _exists(_id);
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
    ) external {
        require(_msgSender() == _admin, Errors.ONLY_ADMIN_ALLOWED);
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Errors.ONLY_ADMIN_ALLOWED);
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

    // withdraw
    // only Admin can withdraw operation fee on this contract
    // receiver: receiver address
    // erc20Addr: currency address
    // amount: amount
    function withdraw(address receiver, address erc20Addr, uint256 amount) external nonReentrant {
        require(_msgSender() == _admin, Errors.ONLY_ADMIN_ALLOWED);
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Errors.ONLY_ADMIN_ALLOWED);
        bool success;
        if (erc20Addr == address(0x0)) {
            require(address(this).balance >= amount);
            (success,) = receiver.call{value : amount}("");
            require(success);
        } else {
            IERC20Upgradeable tokenERC20 = IERC20Upgradeable(erc20Addr);
            // transfer erc-20 token
            require(tokenERC20.transfer(receiver, amount));
        }
    }

    function getParamsTemplate(uint256 id) external view returns (BoilerplateParam.ParamsOfProject memory) {
        return _projects[id]._paramsTemplate;
    }
}