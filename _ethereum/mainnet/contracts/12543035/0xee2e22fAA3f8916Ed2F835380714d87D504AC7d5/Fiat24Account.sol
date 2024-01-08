// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC721PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./DigitsOfUint.sol";

contract Fiat24Account is ERC721PausableUpgradeable, AccessControlUpgradeable {
    using DigitsOfUint for uint256;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint256 private constant DEFAULT_MERCHANT_RATE = 55;

    enum Status { Live, SoftBlocked, Invitee, Blocked, Closed }
    string private constant BASE_URI_METADATA = 'https://api.defi.saphirstein.com/metadata?tokenid=';
    string private constant URI_STATUS_PARAM = '&status=';

    uint8 private constant MERCHANTDIGIT = 8;
    uint8 private constant INTERNALDIGIT = 9;
    uint8 private constant MAXDIGITSACCOUNTID = 8;

    mapping (address => uint256) public historicOwnership;
    mapping (uint256 => string) public nickNames;
    mapping (uint256 => bool) public isMerchant;
    mapping (uint256 => uint256) public merchantRate;
    mapping (uint256 => Status) public status;

    uint8 public minDigitForSale;

    function initialize() public initializer {
        __Context_init_unchained();
        __ERC721_init_unchained("Fiat24 Account", "Fiat24");
        __AccessControl_init_unchained();
        minDigitForSale = 6;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    function mint(address _to, uint256 _tokenId, bool _isMerchant, uint256 _merchantRate) public {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Not an operator");
        require(_mintAllowed(_to, _tokenId), "mint not allowed");
        require(_tokenId.numDigits() <= MAXDIGITSACCOUNTID, "Number of digits of accountId > max. digits");
        _mint(_to, _tokenId);
        status[_tokenId] = Status.Invitee;
        isMerchant[_tokenId] = _isMerchant;
        if(_isMerchant) {
            nickNames[_tokenId] = string(abi.encodePacked("Merchant ", _tokenId.toString()));
            if(_merchantRate == 0) {
                merchantRate[_tokenId] = DEFAULT_MERCHANT_RATE;
            } else {
                merchantRate[_tokenId] = _merchantRate;
            }
        } else {
            nickNames[_tokenId] = string(abi.encodePacked("Tourist ", _tokenId.toString()));
        }
        _setTokenURI(_tokenId, string(abi.encodePacked(BASE_URI_METADATA,
                    _tokenId.toString(),
                    URI_STATUS_PARAM,
                    uint256(Status.Invitee).toString())));
    }

    function mintByClient(uint256 _tokenId) public {
        uint256 numDigits = _tokenId.numDigits();
        require(numDigits <= MAXDIGITSACCOUNTID, "Number of digits of accountId > max. digits");
        require(numDigits >= minDigitForSale, "Premium accountId cannot be mint by client");
        require(!_tokenId.hasFirstDigit(INTERNALDIGIT), "Internal accountId cannot be mint by client");
        require(_mintAllowed(_msgSender(), _tokenId), "Not allowed. The target address has an account or once had another account.");
        bool merchantAccountId = _tokenId.hasFirstDigit(MERCHANTDIGIT);
        _mint(_msgSender(), _tokenId);
        status[_tokenId] = Status.Invitee;
        isMerchant[_tokenId] = merchantAccountId;
        if(merchantAccountId) {
            nickNames[_tokenId] = string(abi.encodePacked("Merchant ", _tokenId.toString()));
            merchantRate[_tokenId] = DEFAULT_MERCHANT_RATE;
        } else {
            nickNames[_tokenId] = string(abi.encodePacked("Tourist ", _tokenId.toString()));
        }
        _setTokenURI(_tokenId, string(abi.encodePacked(BASE_URI_METADATA,
                    _tokenId.toString(),
                    URI_STATUS_PARAM,
                    uint256(Status.Invitee).toString())));
    }

    function burn(uint256 tokenId) public {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Not an operator");
        _burn(tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        super.transferFrom(from, to, tokenId);
        if(status[tokenId] != Status.Invitee) {
            historicOwnership[to] = tokenId;
        }
    }

    function removeHistoricOwnership(address owner) public {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Not an operator");
        delete historicOwnership[owner];
    }

    function changeClientStatus(uint256 tokenId, Status _status) public {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Not an operator");
        if(_status == Status.Live && status[tokenId] == Status.Invitee) {
            historicOwnership[this.ownerOf(tokenId)] = tokenId;
            if(!this.isMerchant(tokenId)) {
                nickNames[tokenId] = string(abi.encodePacked("Account ", tokenId.toString()));
            }
        }
        status[tokenId] = _status;
        _setTokenURI(tokenId, string(abi.encodePacked(BASE_URI_METADATA, tokenId.toString(), URI_STATUS_PARAM, uint256(_status).toString())));
    }

    function setMinDigitForSale(uint8 minDigit) public {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Not an operator");
        minDigitForSale = minDigit;
    }

    function setMerchantRate(uint256 tokenId, uint256 _merchantRate) public {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Not an operator");
        merchantRate[tokenId] = _merchantRate;
    }

    function setNickname(uint256 tokenId, string memory nickname) public {
        require(_msgSender() == this.ownerOf(tokenId), "Not account owner");
        nickNames[tokenId] = nickname;
    }

    function pause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        _pause();
    }

    function unpause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        _unpause();
    }

    function _mintAllowed(address to, uint256 tokenId) internal view returns(bool){
        return (this.balanceOf(to) < 1 && (historicOwnership[to] == 0 || historicOwnership[to] == tokenId));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        require(!paused(), "Account transfers suspended");
        if(AddressUpgradeable.isContract(to) && (from != address(0))) {
            require(this.status(tokenId) == Status.Invitee, "Not allowed to transfer account");
        } else {
                if(from != address(0) && to != address(0)) {
                    require(balanceOf(to) < 1 && (historicOwnership[to] == 0 || historicOwnership[to] == tokenId), "Not allowed. The target address has an account or once had another account.");
                    require(this.status(tokenId) == Status.Live || this.status(tokenId) == Status.Invitee, "Transfer not allowed in this status");
                }
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
}