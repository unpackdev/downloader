// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * @title BurnGhost
 */
contract BurnGhost is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private token_id_counter;
    string public contract_base_uri =
        "https://1874xfgv5l.execute-api.us-east-1.amazonaws.com/dev/tokens/";
    mapping(address => bool) proxies;

    constructor(string memory _name, string memory _ticker)
        ERC721(_name, _ticker)
    {}

    function _baseURI() internal view override returns (string memory) {
        return contract_base_uri;
    }

    function totalSupply() public view returns (uint256) {
        return token_id_counter.current();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(contract_base_uri, Strings.toString(_tokenId))
            );
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTkns = totalSupply();
            uint256 resultIndex = 0;
            uint256 tnkId;

            for (tnkId = 1; tnkId <= totalTkns; tnkId++) {
                if (ownerOf(tnkId) == _owner) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function fixURI(string memory _newURI) external onlyOwner {
        contract_base_uri = _newURI;
    }

    function fixProxy(address _proxy, bool _state) external onlyOwner {
        proxies[_proxy] = _state;
    }

    /*
        This method will mint a new token
    */
    function mintNFT(address _to) external {
        require(proxies[msg.sender], "Only proxies can mint.");
        token_id_counter.increment();
        _mint(_to, token_id_counter.current());
    }
}
