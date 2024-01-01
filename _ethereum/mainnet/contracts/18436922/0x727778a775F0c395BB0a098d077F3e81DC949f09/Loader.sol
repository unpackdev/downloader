// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract Loader {
    struct Request {
        Metadata token;
        uint256[] tokenIds;
    }

    struct Response {
        string name;
        string symbol;
        uint8 decimals;
        string[] tokenURIs;
    }

    function load(
        Request[] calldata _requests
    ) external view returns (Response[] memory responses) {
        responses = new Response[](_requests.length);
        for (uint256 i; i < _requests.length; i++) {
            Request memory request = _requests[i];

            if (address(request.token).code.length == 0) {
                continue;
            }

            Response memory response = responses[i];
            response.tokenURIs = new string[](request.tokenIds.length);

            try request.token.name{gas: 100_000}() returns (
                string memory name
            ) {
                response.name = name;
            } catch {}

            try request.token.symbol{gas: 100_000}() returns (
                string memory symbol
            ) {
                response.symbol = symbol;
            } catch {}

            if (request.tokenIds.length == 0) {
                try request.token.decimals{gas: 30_000}() returns (
                    uint8 decimals
                ) {
                    response.decimals = decimals;
                } catch {}
            }

            for (uint256 j; j < request.tokenIds.length; j++) {
                try
                    request.token.tokenURI{gas: 100_000}(request.tokenIds[j])
                returns (string memory uri) {
                    response.tokenURIs[j] = uri;
                } catch {}
            }
        }
    }
}
