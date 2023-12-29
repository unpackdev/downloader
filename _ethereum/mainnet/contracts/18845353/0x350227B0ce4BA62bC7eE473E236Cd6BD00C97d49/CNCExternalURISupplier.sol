// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenUriSupplier.sol";
import "./CryptoNinjaChildren.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

contract CNCExternalURISupplier is CNCITokenUriSupplier, Ownable, AccessControl
{
    using Strings for uint256;
    using Strings for uint128;

    bytes32 public constant ADMIN = "ADMIN";

    enum TokenType {
        NORMAL,
        RARE
    }

    struct TokenInfo {
        uint64 rareTokenNum;
        uint64 normalTokenNum;
        uint64 rareTokenMax;
        uint64 normalTokenMax;
    }
    TokenInfo public tokenInfo;
    struct UserTokenInfo {
        TokenType tokenType;
        uint128 tokenNum;
    }
    mapping(uint256 => UserTokenInfo) public userTokenInfos;
    string public baseURI;
    string public baseExtension = ".json";

    CryptoNinjaChildren public cnc;

    constructor(address _cnc) Ownable(msg.sender) {
        grantRole(ADMIN, msg.sender);
        cnc = CryptoNinjaChildren(_cnc);
        setRareTokenMax(50);
        setNormalTokenMax(727);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN, _msgSender()), 'Caller is not a admin');
        _;
    }

    function getADMIN() public pure returns (bytes32) {
        return ADMIN;
    }

    function setBaseURI(string memory _baseURI) public onlyAdmin {
        baseURI = _baseURI;
    }

    function setBaseExtension(string memory _baseExtension) public onlyAdmin {
        baseExtension = _baseExtension;
    }

    function setTokenType(uint256 _tokenId, TokenType _tokenType) public onlyAdmin {
        UserTokenInfo storage userTokenInfo = userTokenInfos[_tokenId];

        if (_tokenType == TokenType.RARE) {
            require(tokenInfo.rareTokenNum < tokenInfo.rareTokenMax, "CNCExternalURISupplier: rare token max");

            userTokenInfo.tokenType = TokenType.RARE;
            userTokenInfo.tokenNum = tokenInfo.rareTokenNum;

            tokenInfo.rareTokenNum++;
        } else if(_tokenType == TokenType.NORMAL) {
            require(tokenInfo.normalTokenNum < tokenInfo.normalTokenMax, "CNCExternalURISupplier: normal token max");

            userTokenInfo.tokenType = TokenType.NORMAL;
            userTokenInfo.tokenNum = tokenInfo.normalTokenNum;

            tokenInfo.normalTokenNum++;
        } else {
            revert("CNCExternalURISupplier: invalid token type");
        }
    }

    function setNormalTokenMax(uint64 _normalTokenMax) public onlyAdmin {
        tokenInfo.normalTokenMax = _normalTokenMax;
    }

    function getNormalTokenNum() public view returns (uint64) {
        return tokenInfo.normalTokenNum;
    }

    function setRareTokenMax(uint64 _rareTokenMax) public onlyAdmin {
        tokenInfo.rareTokenMax = _rareTokenMax;
    }

    function getRareTokenNum() public view returns (uint64) {
        return tokenInfo.rareTokenNum;
    }

    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        if (_tokenId <= 11110 || 11888 <= _tokenId) {
            return
                string(
                abi.encodePacked(
                    baseURI,
                    _tokenId.toString(),
                    cnc.isLocked(_tokenId) ? "_lock" : "",
                    baseExtension
                )
            );
        } else {
            return
                string(
                abi.encodePacked(
                    baseURI,
                    userTokenInfos[_tokenId].tokenNum.toString(),
                    userTokenInfos[_tokenId].tokenType == TokenType.RARE ? "_rare" : "_normal",
                    cnc.isLocked(_tokenId) ? "_lock" : "",
                    baseExtension
                )
            );
        }
    }

    function grantRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _revokeRole(role, account);
    }
}
