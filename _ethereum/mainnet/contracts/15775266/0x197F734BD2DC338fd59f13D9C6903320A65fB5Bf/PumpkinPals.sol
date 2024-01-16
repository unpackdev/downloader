 /*

                                      .,'
                                   .'`.'
                                  .' .'
                      _.ood0Pp._ ,'  `.~ .q?00doo._
                  .od00Pd0000Pdb._. . _:db?000b?000bo.
                .?000Pd0000PP?000PdbMb?000P??000b?0000b.
              .d0000Pd0000P'  `?0Pd000b?0'  `?000b?0000b.
             .d0000Pd0000?'     `?d000b?'     `?00b?0000b.
             d00000Pd0000Pd0000Pd00000b?00000b?0000b?0000b
             ?00000b?0000b?0000b?b    dd00000Pd0000Pd0000P
             `?0000b?0000b?0000b?0b  dPd00000Pd0000Pd000P'
              `?0000b?0000b?0000b?0bd0Pd0000Pd0000Pd000P'
                `?000b?00bo.   `?P'  `?P'   .od0Pd000P'
                  `~?00b?000bo._  .db.  _.od000Pd0P~'
                      `~?0b?0b?000b?0Pd0Pd000PdP~'
*/

pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./ERC721A.sol";
import "./Ownable.sol"; 
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol"; 

contract PumpkinPals is ERC721A, Ownable, ReentrancyGuard, PaymentSplitter {

    string public        baseURI;
    uint public          price             = 0.005 ether;
    uint public          maxPerTx          = 2;
    uint public          maxPerWallet      = 2;
    uint public          maxSupply         = 333;
    bool public          mintLive          = false;

    address[] private _payees = [
        0x3183226D0616E15d98C171cc6C9Af22E8cb08Ccf,
        0x793c5393c12E7c361375771e12e9FdE5B55Fb25E
    ];

    uint256[] private _shares = [
        60,
        40
    ];

    constructor() 
    ERC721A("Pumpkin Pals", "PALS")
    PaymentSplitter(_payees, _shares)
    {
        _safeMint(_payees[0], 1);
    }

    function mint(uint256 amt) external payable
    {
        require(mintLive, "Minting is not live yet");
        require( amt < maxPerTx + 1, "One can only have two eyes");
        require(_numberMinted(_msgSender()) < maxPerWallet, "One can only have two eyes. The eye is watching.");
        require(totalSupply() + amt < maxSupply + 1, "Max supply reached");
        require(msg.value == (amt * price), "Send more ETH.");

        _safeMint(msg.sender, amt);
    }

    function toggleMinting() external onlyOwner {
        mintLive = !mintLive;
    }

    function teamClaim() external {
        _safeMint(_payees[0], 19);
        _safeMint(_payees[1], 20);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setmaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner nonReentrant {
        release(payable(_payees[0]));
        release(payable(_payees[1]));
    }
}