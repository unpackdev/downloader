// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

                    /* ,--.
              ,--.  .--,`) )  .--,
           .--,`) \( (` /,--./ (`
          ( ( ,--.  ) )\ /`) ).--,-.
           ;.__`) )/ /) ) ( (( (`_) )
          ( (  / /( (.' "-.) )) )__.'-,
         _,--.( ( /`         `,/ ,--,) )
        ( (``) \,` ==.    .==  \( (`,-;
         ;-,( (_) ~6~ \  / ~6~ (_) )_) )
        ( (_ \_ (      )(      )__/___.'
        '.__,-,\ \     ''     /\ ,-.
           ( (_/ /\    __    /\ \_) )
            '._.'  \  \__/  /  '._.'
                .--`\      /`--.
                     '----'*/

/* HOT DUSA AUTUMN FIRST 100 are a free mint, 0.01 eth afterwards */

import "./ERC721A.sol";
import "./Ownable.sol";


contract DUSATILES is ERC721A, Ownable  {
    uint256 public price = 0.01 ether;
    string private baseURI =
        "https://urbs.ngrok.io/dusa/";
    uint64 public immutable _maxSupply = 500;
    uint24 public maxPerTxn = 10;

    constructor() ERC721A("DUSA Tiles", "DUSA") {}

    function mint(uint256 quantity) external payable {
        require(quantity <= maxPerTxn, "Too many per tx");
        if (totalSupply() >= 100) {
            require(msg.value == price * quantity, "The price is invalid");
        }
        require(
            totalSupply() + quantity <= _maxSupply,
            "Maximum supply exceeded"
        );
        _mint(msg.sender, quantity);
    }

    /**
     * Below is the base URI stuff, it will point to the lyra server, which will
     * be a proxy for more permanent storage solutions such as IPFS.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }

    /**
     * Withdraw function to get ether out of the contract
     */
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Nothing to release");
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }

    receive() external payable {}

}
