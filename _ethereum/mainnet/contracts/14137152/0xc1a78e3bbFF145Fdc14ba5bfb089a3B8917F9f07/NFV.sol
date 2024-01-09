// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./Counters.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Strings.sol";
import "./IERC721Receiver.sol";


/*                                      
        *          .                                     
                   *       '                                                .::.
              *                *                                         .:'  .:
                                                               ,MMM8&&&.:'   .:'
                                                              MMMMM88&&&&  .:'
                                                             MMMMM88&&&&&&:'
                                                             MMMMM88&&&&&&
   *   '*                                                  .:MMMMM88&&&&&&
           *                                             .:'  MMMMM88&&&&
                 *                                     .:'   .:'MMM8&&&'
                        *                            :'  .:'
                *                                     '::'  
                      *


                     _  _     ____________.--.
                  |\|_|//_.-"" .'    \   /|  |
                  |.-"""-.|   /       \_/ |  |
                  \  ||  /| __\_____________ |
                  _\_||_/_| .-""            ""-.  __
                .' '.    \//     Genesis        ".\/
                ||   '. >()_       VAOs          |()<
                ||__.-' |/\ \                    |/\
                   |   / "|  \__________________/.""
                  /   //  | / \ "-.__________/  /\
               ___|__/_|__|/___\___".______//__/__\
              /|\     [____________] \__/         |\
             //\ \     |  |=====| |   /\\         |\\
            // |\ \    |  |=====| |   | \\        | \\        ____...____....----
          .//__| \ \   |  |=====| |   | |\\       |--\\---""""     .            ..
_____....-//___|  \_\  |  |=====| |   |_|_\\      |___\\    .                 ...'
 .      .//-.__|_______|__|_____|_|_____[__\\_____|__.-\\      .     .    ...::
        //        //        /          \ `-_\\/         \\          .....:::
  -... //     .  / /       /____________\    \\       .  \ \     .            .
      //   .. .-/_/-.                 .       \\        .-\_\-.                 .
     / /      '-----'           .             \ \      '._____.'         .
  .-/_/-.         .                          .-\_\-.                          ...
 '._____.'                            .     '._____.'                       .....
        .                                                             ...... ..
    .            .                  .                        .
   ...                    .                      .                       .      .
        ....     .                       .                    ....
  by SpotChain ......           . ..                       ......'
             .......             '...              ....
                                   ''''''      .              .
*/

contract NFV is ERC721, Ownable, IERC721Receiver {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    Counters.Counter private _tokenIds;

    string public baseTokenURI;
    uint public mintPrice = 0.00 ether;

    mapping(address => bool) public addressCanClaim;
    mapping(address => bool) public addressCanTransfer;

    bool private _transferEnabled = false;


    constructor() ERC721("Genesis VAOs", "VAO") {
        // VAOs are born...
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setTransferEnabled(bool value) external onlyOwner {
        _transferEnabled = value;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function addAddressToClaim(address addAddress) external onlyOwner {
        addressCanClaim[addAddress] = true;
    }

    function removeAddressFromClaim(address removeAddress) external onlyOwner {
        addressCanClaim[removeAddress] = false;
    }

    function addAddressToTransfer(address addAddress) external onlyOwner {
        addressCanTransfer[addAddress] = true;
    }

    function removeAddressToTransfer(address removeAddress) external onlyOwner {
        addressCanTransfer[removeAddress] = false;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function amountMinted() external view returns (uint256) {
        return _tokenIds.current();
    }

    function fetchContractBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


    // Vibes are non sellable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal view override {
        require(addressCanTransfer[from] || _transferEnabled, "Vibe is not transferable");
    }


    // Claim Your Vibe!
    function claimVibe(uint256 tokenId) external payable {
        require(addressCanClaim[msg.sender], "You are not on the list");
        require(balanceOf(msg.sender) < 1, "too many");
        require(msg.value == mintPrice, "Valid price not sent");
        _transferEnabled = true;
        addressCanClaim[msg.sender] = false;
        IERC721(this).safeTransferFrom(address(this), msg.sender, tokenId);
        _transferEnabled = false;
    }

    // Creation of Vibes
    function vibeFactory(uint256 num) external onlyOwner {
        uint256 newItemId = _tokenIds.current();
        _transferEnabled = true;
        for (uint256 i; i < num; i++) {
            _tokenIds.increment();
            newItemId = _tokenIds.current();
            _safeMint(address(this), newItemId);
        }
        setApprovalForAll(address(this), true);
        _transferEnabled = false;
    }

}
