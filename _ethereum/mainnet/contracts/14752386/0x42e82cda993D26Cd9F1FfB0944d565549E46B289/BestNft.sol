pragma solidity ^0.8.13;
// SPDX-License-Identifier: UNLICENSED
/*
 * (c) Copyright 2022 Masalsa, Inc., all rights reserved.
  You have no rights, whatsoever, to fork, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software.
  By using this file/contract, you agree to the Customer Terms of Service at nftdeals.xyz
  THE SOFTWARE IS PROVIDED AS-IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  This software is Experimental, use at your own risk!
 */

import "./ERC721PresetMinterPauserAutoId.sol";
import "./base64.sol";
import "./Strings.sol";

contract BestNft is ERC721PresetMinterPauserAutoId {
    constructor() ERC721PresetMinterPauserAutoId("Testnet BAYC", "BAYC", "http://"){ }
    using Strings for uint;
    using Counters for Counters.Counter;
    Counters.Counter public tokenIdTracker;

    string[] public image_urls = [
        'https://nftdeals.xyz/assets/img/debug/testnet-bayc-1.png',
        'https://nftdeals.xyz/assets/img/debug/testnet-bayc-2.png',
        'https://nftdeals.xyz/assets/img/debug/testnet-bayc-3.png',
        'https://nftdeals.xyz/assets/img/debug/testnet-bayc-4.png'
    ];

    // https://docs.opensea.io/docs/metadata-standards
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory image_url = image_urls[tokenId % image_urls.length];
        string memory json = Base64.encode(
          bytes(
              string(
                  abi.encodePacked(
                      '{"name": "Testnet BAYC", "description": "for testing", "image": "', image_url, '"}'
                  )
              )
          )
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function mint(address to) public override {
        _mint(to, tokenIdTracker.current());
        tokenIdTracker.increment();
    }
}