// SPDX-License-Identifier: ISC

pragma solidity ^0.7.5;
pragma experimental ABIEncoderV2;

// target contract interface - selection of used ERC20 and ERC721 methods
abstract contract Target {
    function name() public virtual view returns (string memory);

    function symbol() public virtual view returns (string memory);

    function decimals() public virtual view returns (uint8);

    function totalSupply() public virtual view returns (uint256);

    // Method from ERC165 interface used to check whether the contract is ERC721
    function supportsInterface(bytes4 interfaceID)
        external
        virtual
        view
        returns (bool);
}

contract TokenLoader {
    struct TokenInfo {
        address addr; // address of the token contract
        bool definitelyIsERC721; // can be resolved only when the token implements ERC165
        string name; // mandatory in ERC20, voluntary in ERC721 (ERC721Metadata interface)
        string symbol; // mandatory in ERC20, voluntary in ERC721 (ERC721Metadata interface)
        uint8 decimals; // mandatory in ERC20
        uint256 totalSupply; // mandatory in ERC20, voluntary in ERC721 (ERC721Enumerable interface)
    }

    function loadTokens(address[] calldata tokens)
        external
        view
        returns (TokenInfo[] memory tokenInfo)
    {
        tokenInfo = new TokenInfo[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (!isContract(tokens[i])) {
                continue;
            }
            Target target = Target(tokens[i]);

            tokenInfo[i].addr = tokens[i];

            tokenInfo[i].definitelyIsERC721 = definitelyIsERC721(target);

            (bool success, bytes memory returnData) = address(target)
                .staticcall(abi.encodeWithSelector(target.name.selector));
            if (success) {
                tokenInfo[i].name = abi.decode(returnData, (string));
            } else {
                tokenInfo[i].name = '';
            }

            (success, returnData) = address(target).staticcall(
                abi.encodeWithSelector(target.symbol.selector)
            );
            if (success) {
                tokenInfo[i].symbol = abi.decode(returnData, (string));
            } else {
                tokenInfo[i].symbol = '';
            }

            (success, returnData) = address(target).staticcall(
                abi.encodeWithSelector(target.decimals.selector)
            );
            if (success) {
                tokenInfo[i].decimals = abi.decode(returnData, (uint8));
            } else {
                tokenInfo[i].decimals = 0;
            }

            (success, returnData) = address(target).staticcall(
                abi.encodeWithSelector(target.totalSupply.selector)
            );
            if (success) {
                tokenInfo[i].totalSupply = abi.decode(returnData, (uint256));
            } else {
                tokenInfo[i].totalSupply = 0;
            }
        }

        return tokenInfo;
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function definitelyIsERC721(Target target) private view returns (bool) {
        // 0x80ac58cd - ERC721 ID
        (bool success, bytes memory returnData) = address(target).staticcall(
            abi.encodeWithSelector(
                target.supportsInterface.selector,
                0x80ac58cd
            )
        );
        return success && abi.decode(returnData, (bool));
    }
}
