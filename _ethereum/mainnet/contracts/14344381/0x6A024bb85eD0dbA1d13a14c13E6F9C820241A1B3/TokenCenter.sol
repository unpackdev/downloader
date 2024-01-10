// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EnumerableSet.sol";
import "./Ownable.sol";

struct Token {
    address token;
    string symbol;
}

contract TokenCenter is Ownable {
    
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private supportTokenSet;

    mapping(address => string) tokenToSymbol;
    mapping(string => address) SymbolToToken;

    mapping(address => bool) canBeLeverage;
    mapping(address => bool) canBeLong;
    mapping(address => bool) canBeShort;

    uint256 leverageTokenCount;
    uint256 longTokenCount;
    uint256 shortTokenCount;

    function addSupportToken(address token, string memory tokenSymbol)
        external
        onlyOwner
    {
        require(token != address(0), "CHFRY: Token address is 0");
        require(bytes(tokenSymbol).length != 0, "CHFRY: tokenSymbol should not be blank");
        require(
            EnumerableSet.contains(supportTokenSet, token) == false,
            "CHFRY: Token already in the Support Set"
        );
        EnumerableSet.add(supportTokenSet, token);
        tokenToSymbol[token] = tokenSymbol;
        SymbolToToken[tokenSymbol] = token;
    }

    function removeSuportToken(address token) external onlyOwner {
        require(token != address(0), "CHFRY: Token address is 0");
        require(
            EnumerableSet.contains(supportTokenSet, token),
            "CHFRY: Token not in the Support Set"
        );

        EnumerableSet.remove(supportTokenSet, token);

        SymbolToToken[tokenToSymbol[token]] = address(0);
        tokenToSymbol[token] = '';

        if (canBeLong[token]) {
            longTokenCount = longTokenCount - 1;
            canBeLong[token] = false;
        }

        if (canBeShort[token]) {
            shortTokenCount = shortTokenCount - 1;
            canBeShort[token] = false;
        }

        if (canBeLeverage[token]) {
            leverageTokenCount = leverageTokenCount - 1;
            canBeLeverage[token] = false;
        }
    }

    function enableTokenAsLong(address token) external onlyOwner {
        require(token != address(0), "CHFRY: Token address is 0");
        require(
            EnumerableSet.contains(supportTokenSet, token),
            "CHFRY: Token not in the Support Set"
        );
        require(canBeLong[token] == false, "CHFRY: Token already Longable");
        canBeLong[token] = true;
        longTokenCount = longTokenCount + 1;
    }

    function disableTokenAsLong(address token) external onlyOwner {
        require(token != address(0), "CHFRY: Token address is 0");
        require(
            EnumerableSet.contains(supportTokenSet, token),
            "CHFRY: Token not in the Support Set"
        );
        require(canBeLong[token] == true, "CHFRY: Token already not Longable");
        canBeLong[token] = false;
        longTokenCount = longTokenCount - 1;
    }

    function enableTokenAsShort(address token) external onlyOwner {
        require(token != address(0), "CHFRY: Token address is 0");
        require(
            EnumerableSet.contains(supportTokenSet, token),
            "CHFRY: Token not in the Support Set"
        );
        require(canBeShort[token] == false, "CHFRY: Token already Shortable");
        canBeShort[token] = true;
        shortTokenCount = shortTokenCount + 1;
    }

    function disableTokenAsShort(address token) external onlyOwner {
        require(token != address(0), "CHFRY: Token address is 0");
        require(
            EnumerableSet.contains(supportTokenSet, token),
            "CHFRY: Token not in the Support Set"
        );
        require(
            canBeShort[token] == true,
            "CHFRY: Token already not Shortable"
        );
        canBeShort[token] = false;
        shortTokenCount = shortTokenCount - 1;
    }

    function enableTokenAsLeverage(address token) external onlyOwner {
        require(token != address(0), "CHFRY: Token address is 0");
        require(
            EnumerableSet.contains(supportTokenSet, token),
            "CHFRY: Token not in the Support Set"
        );
        require(
            canBeLeverage[token] == false,
            "CHFRY: Token already is Leverage Token"
        );
        canBeLeverage[token] = true;
        leverageTokenCount = leverageTokenCount + 1;
    }

    function disableTokenAsLeverage(address token) external onlyOwner {
        require(token != address(0), "CHFRY: Token address is 0");
        require(
            EnumerableSet.contains(supportTokenSet, token),
            "CHFRY: Token not in the Support Set"
        );
        require(
            canBeLeverage[token] == true,
            "CHFRY: Token is not Leverage Token"
        );
        canBeLeverage[token] = false;
        leverageTokenCount = leverageTokenCount - 1;
    }

    function listLeverageToken()
        external
        view
        returns (Token[] memory tokenList)
    {
        uint256 length = EnumerableSet.length(supportTokenSet);
        uint256 n = 0;
        tokenList = new Token[](leverageTokenCount);
        for (uint256 i = 0; i < length; i++) {
            address token = EnumerableSet.at(supportTokenSet, i);
            if (canBeLeverage[token] == true) {
                tokenList[n].token = token;
                tokenList[n].symbol = tokenToSymbol[token];
                n = n + 1;
            }
        }
    }

    function listLongToken() external view returns (Token[] memory tokenList) {
        uint256 length = EnumerableSet.length(supportTokenSet);
        uint256 n = 0;
        tokenList = new Token[](longTokenCount);
        for (uint256 i = 0; i < length; i++) {
            address token = EnumerableSet.at(supportTokenSet, i);
            if (canBeLong[token] == true) {
                tokenList[n].token = token;
                tokenList[n].symbol = tokenToSymbol[token];
                n = n + 1;
            }
        }
    }

    function listShortToken() external view returns (Token[] memory tokenList) {
        uint256 length = EnumerableSet.length(supportTokenSet);
        uint256 n = 0;
        tokenList = new Token[](shortTokenCount);
        for (uint256 i = 0; i < length; i++) {
            address token = EnumerableSet.at(supportTokenSet, i);
            if (canBeShort[token] == true) {
                tokenList[n].token = token;
                tokenList[n].symbol = tokenToSymbol[token];
                n = n + 1;
            }
        }
    }

    function isLeverageable(address token) external view returns (bool leverageable) {
        leverageable = canBeLeverage[token];
    }

    function isLongable(address token) external view returns (bool longable) {
        longable = canBeLong[token];
    }

    function isShortable(address token) external view returns (bool shortable) {
        shortable = canBeShort[token];
    }
}
