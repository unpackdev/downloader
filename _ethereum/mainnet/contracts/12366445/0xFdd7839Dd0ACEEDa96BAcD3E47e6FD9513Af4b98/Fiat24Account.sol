// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC721PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
//import "./EnumerableAddressToUintMapUpgradeable.sol";
import "./DigitsOfUint.sol";
import "./F24.sol";
import "./Fiat24PriceList.sol";

contract Fiat24Account is ERC721PausableUpgradeable, AccessControlUpgradeable {
    //using EnumerableAddressToUintMapUpgradeable for EnumerableAddressToUintMapUpgradeable.AddressToUintMap;
    using DigitsOfUint for uint256;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint256 private constant DEFAULT_MERCHANT_RATE = 55;

    // keep the order of Status
    enum Status { Live, SoftBlocked, Invitee, Blocked, Closed, Na}
    string private constant BASE_URI_METADATA = 'https://api.defi.saphirstein.com/metadata?tokenid=';
    string private constant URI_STATUS_PARAM = '&status=';

    uint8 private constant MERCHANTDIGIT = 8;
    uint8 private constant INTERNALDIGIT = 9;
    uint8 private constant MAXDIGITSACCOUNTID = 8;

    //EnumerableAddressToUintMapUpgradeable.AddressToUintMap private _tokenOwnersHistoric;
    mapping (address => uint256) private _tokenOwnersHistoric;

    // F24 f24;
    // Fiat24PriceList fiat24PriceList;

    mapping (uint256 => string) public nickNames;
    mapping (uint256 => bool) public isMerchant;
    mapping (uint256 => uint256) public merchantRate;
    mapping (uint256 => Status) public status;

    uint8 public minDigitForSale;

    function initialize(/*address _f24Address, address _fiat24PriceListAddress*/) public initializer {
        __Context_init_unchained();
        __ERC721_init_unchained("Fiat24 Account", "Fiat24");
        __AccessControl_init_unchained();
        // f24 = F24(_f24Address);
        // fiat24PriceList = Fiat24PriceList(_fiat24PriceListAddress);
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

    // function mintByF24(uint256 _tokenId) public {
    //     require(_tokenId.numDigits() <= MAXDIGITSACCOUNTID, "Number of digits of accountId > max. digits");
    //     require(!_tokenId.hasFirstDigit(INTERNALDIGIT), "AccountId not allowed to mint");
    //     uint256 accountPrice = fiat24PriceList.getPrice(_tokenId);
    //     require(accountPrice != 0, "AccountId not available");
    //     require(f24.allowance(_msgSender(), address(this)) >= accountPrice, "Not enough allowance for mintByF24");
    //     require(_mintAllowed(_msgSender(), _tokenId), "mint not allowed");
    //     bool merchantAccountId = _tokenId.hasFirstDigit(MERCHANTDIGIT);
    //     f24.burnFrom(_msgSender(), accountPrice);
    //     _mint(_msgSender(), _tokenId);
    //     status[_tokenId] = Status.Invitee;
    //     //_tokenOwnersHistoric.set(_to, _tokenId);
    //     //_tokenOwnersHistoric[_msgSender()] = _tokenId;
    //     isMerchant[_tokenId] = merchantAccountId;
    //     if(merchantAccountId) {
    //         nickNames[_tokenId] = string(abi.encodePacked("Merchant ", _tokenId.toString()));
    //         merchantRate[_tokenId] = DEFAULT_MERCHANT_RATE;
    //     } else {
    //         nickNames[_tokenId] = string(abi.encodePacked("Tourist ", _tokenId.toString()));
    //     }
    //     _setTokenURI(_tokenId, string(abi.encodePacked(BASE_URI_METADATA,
    //                 _tokenId.toString(),
    //                 URI_STATUS_PARAM,
    //                 uint256(Status.Invitee).toString())));
    // }

    function mintByClient(uint256 _tokenId) public {
        uint256 numDigits = _tokenId.numDigits();
        require(numDigits <= MAXDIGITSACCOUNTID, "Number of digits of accountId > max. digits");
        require(numDigits >= minDigitForSale, "Minimal digits limit of accountId broken");
        require(!_tokenId.hasFirstDigit(INTERNALDIGIT), "AccountId not allowed to mint");
        require(_mintAllowed(_msgSender(), _tokenId), "mint not allowed");
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
        //_tokenOwnersHistoric.set(to, tokenId);
        if(status[tokenId] != Status.Invitee) {
            _tokenOwnersHistoric[to] = tokenId;
        }
    }

    function getAccountOfAddress(address owner) public view returns(uint256) {
        return _tokenOwnersHistoric[owner];
    }

    function removeHistoricOwnership(address owner) public {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Not an operator");
        //_tokenOwnersHistoric.remove(owner);
        delete _tokenOwnersHistoric[owner];
    }

    //   function setClientStatusLive(uint256 tokenId, string memory nickname) public  {
    //       require(hasRole(OPERATOR_ROLE, msg.sender), "Not an operator");
    //       require(status[tokenId] == Status.Invitee, "Status not Invitee");
    //       status[tokenId] = Status.Live;
    //       nickNames[tokenId] = nickname;
    //       _setTokenURI(tokenId, string(abi.encodePacked(BASE_URI_METADATA, tokenId.toString(), URI_STATUS_PARAM, uint256(Status.Live).toString())));
    //   }

    function changeClientStatus(uint256 tokenId, Status _status) public {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Not an operator");
        // First time live
        // => set historic ownership of address
        // => change the default nickname of client from "Tourist nnnnnnnn" to "Account nnnnnnnn
        if(_status == Status.Live && status[tokenId] == Status.Invitee) {
            _tokenOwnersHistoric[this.ownerOf(tokenId)] = tokenId;
            if(!this.isMerchant(tokenId)) {
                nickNames[tokenId] = string(abi.encodePacked("Account ", tokenId.toString()));
            }
        }
        //require(!(_status == Status.Live && status[tokenId] == Status.Invitee), "Use setClientStatusLive to set Live");
        // if(_status == Status.Live) {
        //     if(_tokenOwnersHistoric[ownerOf(tokenId)] == 0 && !this.isMerchant(tokenId)) {
        //         nickNames[tokenId] = string(abi.encodePacked("Account ", tokenId.toString()));
        //     }
        //     _tokenOwnersHistoric[ownerOf(tokenId)] = tokenId;
        // }
        status[tokenId] = _status;
        _setTokenURI(tokenId, string(abi.encodePacked(BASE_URI_METADATA, tokenId.toString(), URI_STATUS_PARAM, uint256(_status).toString())));
    }

    // function getAddressStatus(address owner) public view returns(Fiat24Account.Status){
    //     uint256 balance = balanceOf(owner);
    //     Fiat24Account.Status _status = Fiat24Account.Status.Na;
    //     Fiat24Account.Status _tempStatus;
    //     for(uint256 i = 0; i < balance; i++) {
    //         _tempStatus = this.status(this.tokenOfOwnerByIndex(owner, i));
    //         if(_tempStatus < _status) {
    //             _status = _tempStatus;
    //         }
    //     }
    //     return _status;
    // }

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
        return (this.balanceOf(to) < 1 && (_tokenOwnersHistoric[to] == 0 || _tokenOwnersHistoric[to] == tokenId));
        //return _tokenOwnersHistoric[to] == 0 || _tokenOwnersHistoric[to] == tokenId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        require(!paused(), "Account transfers suspended");
        if(AddressUpgradeable.isContract(to) && (from != address(0))) {
            require(this.status(tokenId) == Status.Invitee, "Not allowed to transfer account");
        } else {
                //require(_tokenOwnersHistoric[to] == 0 || _tokenOwnersHistoric[to] == tokenId, "Receiver has already account");
                // require((status[tokenId] == Status.Live && balanceOf(to) < 1 && (_tokenOwnersHistoric[to] == 0 || _tokenOwnersHistoric[to] == tokenId)) ||
                //         (status[tokenId] == Status.Invitee && _tokenOwnersHistoric[to] == 0), "Receiver has already account or account is blocked");
                if(from != address(0) && to != address(0)) {
                    require(balanceOf(to) < 1 && (_tokenOwnersHistoric[to] == 0 || _tokenOwnersHistoric[to] == tokenId), "Receiver has already account or account is blocked");
                    require(this.status(tokenId) == Status.Live || this.status(tokenId) == Status.Invitee, "Transfer not allowed in this status");
                }
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
}