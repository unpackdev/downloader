// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Counters.sol";
import "./ERC20Upgradeable.sol";

import "./ERC1155TradableUpgradeable.sol";
import "./ParameterControl.sol";

/*
 * TODO:
 * [] Use ERC1155 https://docs.openzeppelin.com/contracts/3.x/erc1155
 * [] 
 *
 */

contract AvatarNFT is ERC1155TradableUpgradeable {
    event UserCreateEvent (address _initialOwner, uint256 _id, uint256 _initialSupply, string _uri, address _creator, bytes _data);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public newItemId;
    address public parameterControlAdd;
    address public erc20TokenFeeUserCreate;
    mapping(uint256 => address) public freezers;

    function initialize(address admin, address operator, string memory name, string memory symbol, string memory uri) initializer public {
        ERC1155TradableUpgradeable.initialize(
            name,
            symbol,
            uri,
            admin,
            operator);
    }

    function create(
        address _initialOwner,
        uint256 _id,
        uint256 _initialSupply,
        string memory _uri,
        bytes memory _data,
        address erc_20,
        int256 _price,
        uint256 _max
    ) public operatorOnly override
    returns (uint256) {
        return 0;
    }

    function userMint(address _to,
        uint256 _id,
        address erc_20,
        uint256 _quantity,
        bytes memory _data
    ) public payable override {}

    function userCreateNFT(
        address _initialOwner,
        uint256 _initialSupply,
        string memory _uri,
        bytes memory _data
    )
    external
    payable
    returns (uint256) {
        _tokenIds.increment();
        newItemId = _tokenIds.current();

        require(!_exists(newItemId), "A_E");
        require(_initialSupply > 0, "I_I");

        ParameterControl _p = ParameterControl(parameterControlAdd);
        // get fee for mint
        uint256 mintFEE = _p.getUInt256("CREATE_AVATAR_FEE");
        bool isNativeToken = erc20TokenFeeUserCreate == address(0x0);
        if (mintFEE > 0 && _msgSender() != operator) {
            if (isNativeToken) {
                require(msg.value >= mintFEE * _initialSupply, "I_F");
            } else {
                ERC20Upgradeable tokenERC20 = ERC20Upgradeable(erc20TokenFeeUserCreate);
                // tranfer erc-20 token to this contract
                bool success = tokenERC20.transferFrom(_msgSender(), address(this), mintFEE * _initialSupply);
                require(success == true, "T_F");
            }
        }

        creators[newItemId] = operator;
        freezers[newItemId] = _msgSender();

        if (bytes(_uri).length > 0) {
            customUri[newItemId] = _uri;
            emit URI(_uri, newItemId);
        }

        _mint(_initialOwner, newItemId, _initialSupply, _data);
        tokenSupply[newItemId] = _initialSupply;

        max_supply_tokens[newItemId] = _initialSupply;

        emit UserCreateEvent(_initialOwner, newItemId, _initialSupply, _uri, _msgSender(), _data);
        return newItemId;
    }

    function userFreezeCustomURI(
        uint256 _tokenId,
        string memory _newURI
    ) public {
        require(_msgSender() == freezers[newItemId], "ONLY_FREEZER");
        customUri[_tokenId] = _newURI;
        emit URI(_newURI, _tokenId);
    }

    function changeParameterControl(address _new) external adminOnly {
        require(_new != address(0x0), "ADDRESS_INVALID");
        parameterControlAdd = _new;
    }

    function changeUserCreateFee(address _new) external operatorOnly {
        require(_new != address(0x0), "ADDRESS_INVALID");
        erc20TokenFeeUserCreate = _new;
    }
}
