/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!???!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~?GPG?~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~YPPPY~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~?PPPPP?~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~YPPPPPY~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!5PPPPP5!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~?Y55555PPPPPPP55555Y?~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~7PPPPPPPPPPPPPPPPPPPPP7~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^?PPPPPPPPPPPPPPPPPPPPP7~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~!7???YPPPPPPPPPPPPPPPPPPPPPYJ???7!~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~75PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP57~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPP5J?7?JYPPPPPPPPYJ?7?J5PPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPY^.      :?PPPP?:      .^YPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPJ    :~:    !PP!    :~:    JPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPP~   .G@#^   .PP.   ^#@G.   ^PPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPP?    ^!~    ~PP~    ~!^    ?PPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPYJJJJJJJJJYPPPPJJJJJJJJJJYPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPGBPPPPPPBGPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPBBBBBBBBPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~!PPPPPPPPPPPPPPPPPPGGPPPPPPPPPPPPPPPPPP!~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~75PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP57~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~!?Y5PPPPPPPPPPPPPPPPPPPPPPPPPPPP5Y?~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!7?JJJJYY555PGGGGG5YYYJ????7!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^.     . ^&B77G&^       .^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^          ^.   :..        ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.     :      .. :^^^ .     .~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^:.:              :.:^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~5PPP?~!!!!.!!77!!:!!!!~?PPP5~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~5PPP?~~^^^.^^^^^^.^^^~~JPPP5~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~5PPPY~:              :~5PPP5~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~5PPPP?:      .:      :?PPPP5~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~5PP5!!:      ^^      :!!5PP5~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!777~~:      ^^      :~~777!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:      ^^      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:      ^:      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^::... ^: ....:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!77?Y#@&BBG!~~!GGG&@#Y?77~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^:~?JY55555YY!~~!Y555555YJ?~:^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^~~~~^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "./Ownable.sol";

contract GVMToken is ERC721A, Ownable {
    // private

    string private baseURI;

    address private constant gvmCorporateA =
        0xD487291e9b1a37dF24dF39A240C3d3bf2653f361;

    address private constant gvmCorporateB =
        0xC5DB8C6855c264d35A1a60180BCDE2bdDEABCe69;

    // public

    bool public openForBusiness = false;

    uint256 public constant maxSupply = 8888;
    uint256 public constant maxMint = 1;

    bool public corporateDidClaim = false;
    uint256 public constant corporateClaimAmount = 222;

    mapping(address => uint256) public claimedAmount;

    constructor() ERC721A("Grindset Value Menu", "GVM") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function openUp(bool _openForBusiness) external onlyOwner {
        openForBusiness = _openForBusiness;
    }

    function corporateClaim() external onlyOwner {
        require(!corporateDidClaim, "Corporate has already claimed their GVMs");

        _safeMint(gvmCorporateA, corporateClaimAmount);
        _safeMint(gvmCorporateB, corporateClaimAmount);

        corporateDidClaim = true;
    }

    function mint() external {
        require(openForBusiness, "Sorry, we are closed");
        require(
            totalSupply() < maxSupply,
            "Sorry, the soft serve machine is permanently broken"
        );
        require(
            claimedAmount[_msgSender()] < maxMint,
            "Sorry, you have already received your free GVM"
        );

        claimedAmount[_msgSender()] += 1;
        _safeMint(_msgSender(), 1);
    }
}
