// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

import "./ERC721A.sol";

/**
   _____           _       _       _              
  / ____|         | |     | |     (_)             
 | |       _   _  | |__   | |__    _    ___   ___ 
 | |      | | | | | '_ \  | '_ \  | |  / _ \ / __|
 | |____  | |_| | | |_) | | |_) | | | |  __/ \__ \
  \_____|  \__,_| |_.__/  |_.__/  |_|  \___| |___/

  Website: https://cubbiesnft.net/
  Founder: https://twitter.com/yunkjard
                                                                                                              
*/

contract Cubbies is Ownable, ERC721A, ReentrancyGuard {

    using Strings for uint256;

    string public baseURI = "https://cubbiesnft.net/api/metadata/";
    string public _contractURI = "https://cubbiesnft.net/api/contract/";

    address public withdrawalAddress;

    constructor(address _withdrawalAddress) ERC721A("Cubbies", "CUBBIES") {
        withdrawalAddress = _withdrawalAddress;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setContractURI(string memory newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setWithdrawalAddress(address addr) public onlyOwner {
        withdrawalAddress = addr;
    }

    function mint(address destination, uint256 amount) public onlyOwner {
        _safeMint(destination, amount);
    }

    function withdraw() public onlyOwner {
        require(payable(withdrawalAddress).send(address(this).balance));
    }
}