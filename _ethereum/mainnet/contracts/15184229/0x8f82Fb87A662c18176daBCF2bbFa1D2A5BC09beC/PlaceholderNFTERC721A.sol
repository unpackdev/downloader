// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Base64.sol";

contract PlaceholderNFTERC721A is ERC721A {
    constructor() ERC721A("Placeholder NFT (ERC721A)", "PNFT-ERC721A") {}

    function mint(uint256 quantity) external {
        _mint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        // Get all the JSON metadata in place and base64 encode it.
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        string(
                            abi.encodePacked(
                                "Placeholder NFT (ERC721A) #",
                                Strings.toString(tokenId)
                            )
                        ),
                        '", "description": "Placeholder NFT is an unlimited supply, fully on-chain, NFT collection available on any EVM-compatible chain. You may mint it freely, and use it for testing, or your own satisfaction.", "image": "data:image/svg+xml;base64,PHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHZpZXdCb3g9JzExIDExIDUwIDUwJz48Zz48cmVjdCB4PScxMicgeT0nMTInIHdpZHRoPSc0OCcgaGVpZ2h0PSc0OCcgZmlsbD0nI0E1NzkzOScgc3Ryb2tlPSdub25lJyBzdHJva2UtbGluZWNhcD0ncm91bmQnIHN0cm9rZS1saW5lam9pbj0ncm91bmQnIHN0cm9rZS1taXRlcmxpbWl0PScxMCcgc3Ryb2tlLXdpZHRoPScyJz48L3JlY3Q+PHJlY3QgeD0nMTgnIHk9JzE4JyB3aWR0aD0nMzYnIGhlaWdodD0nMzYnIGZpbGw9JyM5MkQzRjUnIHN0cm9rZT0nbm9uZScgc3Ryb2tlLWxpbmVjYXA9J3JvdW5kJyBzdHJva2UtbGluZWpvaW49J3JvdW5kJyBzdHJva2UtbWl0ZXJsaW1pdD0nMTAnIHN0cm9rZS13aWR0aD0nMic+PC9yZWN0PjxjaXJjbGUgY3g9JzI2JyBjeT0nMzAnIHI9JzQnIGZpbGw9JyNGQ0VBMkInIHN0cm9rZT0nbm9uZScgc3Ryb2tlLWxpbmVjYXA9J3JvdW5kJyBzdHJva2UtbGluZWpvaW49J3JvdW5kJyBzdHJva2UtbWl0ZXJsaW1pdD0nMTAnIHN0cm9rZS13aWR0aD0nMic+PC9jaXJjbGU+PHBhdGggZmlsbD0nIzVDOUUzMScgc3Ryb2tlPScjNUM5RTMxJyBzdHJva2UtbGluZWNhcD0ncm91bmQnIHN0cm9rZS1saW5lam9pbj0ncm91bmQnIHN0cm9rZS1taXRlcmxpbWl0PScxMCcgc3Ryb2tlLXdpZHRoPScyJyBkPSdNNTAsMzVjLTIuODk1OC0wLjg1NDItNi4yNzk1LTcuOTg4Ni04LThjLTQuMjA4LTAuMDI3OC02LjI1NCw1LjgzNi0xMSw5Yy0zLDItMy4zNzQ1LDIuODQ5Ny02LDRjLTIuMjgyNCwxLTMsMy0zLjI1LDMuNjQwNiBjLTAuMzAzMSwwLjc3NjYtMS40NzUxLDIuNTIxNC0wLjk1ODMsMy4xMDk0YzEuMjA4MywxLjM3NSwyLjQ1ODMsMS41LDUsMC43MTc5YzIuMTQ3LTAuNjYwNiw0Ljk3NjktNC44MDc0LDYuODc1LTYuMjE3OSBjMi4yNzA4LTEuNjg3NSw0LjY0NTgtMi41LDguMDgzMy0yYzIuNDc5NSwwLjM2MDYsNi42NiwzLjE3MjMsNy44MTI1LDMuMDYyNWMxLjMxMjUtMC4xMjUtMS41OTM3LTIuNTYyNS0wLjUzMTItNC4xODc1IGMxLjEzMjctMS43MzI1LDIuOTEwMiwwLjE1MjksMy42MzU0LTEuMDgzM0M1MS45ODQ0LDM2LjUsNTAuNjMyLDM1LjE4NjQsNTAsMzV6Jz48L3BhdGg+PC9nPjxnPjxyZWN0IHg9JzEyJyB5PScxMicgd2lkdGg9JzQ4JyBoZWlnaHQ9JzQ4JyBmaWxsPSdub25lJyBzdHJva2U9JyMwMDAwMDAnIHN0cm9rZS1saW5lY2FwPSdyb3VuZCcgc3Ryb2tlLWxpbmVqb2luPSdyb3VuZCcgc3Ryb2tlLW1pdGVybGltaXQ9JzEwJyBzdHJva2Utd2lkdGg9JzInPjwvcmVjdD48cmVjdCB4PScxOCcgeT0nMTgnIHdpZHRoPSczNicgaGVpZ2h0PSczNicgZmlsbD0nbm9uZScgc3Ryb2tlPScjMDAwMDAwJyBzdHJva2UtbGluZWNhcD0ncm91bmQnIHN0cm9rZS1saW5lam9pbj0ncm91bmQnIHN0cm9rZS1taXRlcmxpbWl0PScxMCcgc3Ryb2tlLXdpZHRoPScyJz48L3JlY3Q+PGNpcmNsZSBjeD0nMjYnIGN5PSczMCcgcj0nNCcgZmlsbD0nbm9uZScgc3Ryb2tlPScjMDAwMDAwJyBzdHJva2UtbGluZWNhcD0ncm91bmQnIHN0cm9rZS1saW5lam9pbj0ncm91bmQnIHN0cm9rZS1taXRlcmxpbWl0PScxMCcgc3Ryb2tlLXdpZHRoPScyJz48L2NpcmNsZT48cmVjdCB4PScxOCcgeT0nMTgnIHdpZHRoPSczNicgaGVpZ2h0PSczNicgZmlsbD0nbm9uZScgc3Ryb2tlPScjMDAwMDAwJyBzdHJva2UtbGluZWNhcD0ncm91bmQnIHN0cm9rZS1saW5lam9pbj0ncm91bmQnIHN0cm9rZS1taXRlcmxpbWl0PScxMCcgc3Ryb2tlLXdpZHRoPScyJz48L3JlY3Q+PHBhdGggZmlsbD0nbm9uZScgc3Ryb2tlPScjMDAwMDAwJyBzdHJva2UtbGluZWNhcD0ncm91bmQnIHN0cm9rZS1saW5lam9pbj0ncm91bmQnIHN0cm9rZS1taXRlcmxpbWl0PScxMCcgc3Ryb2tlLXdpZHRoPScyJyBkPSdNMjIsNDNjMC41MjU5LTEuMDE5OCwwLjcyNzUtMS45NjcyLDMtM2MyLjYwOTYtMS4xODU5LDMtMiw2LTRjNC43NDYtMy4xNjQsNi43OTItOS4wMjc4LDExLTljMS43MjA1LDAuMDExNCw1LDcsOCw4Jz48L3BhdGg+PC9nPjwvc3ZnPg=="}'
                    )
                )
            )
        );

        // Prepend data:application/json;base64, to our data.
        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return finalTokenUri;
    }
}
