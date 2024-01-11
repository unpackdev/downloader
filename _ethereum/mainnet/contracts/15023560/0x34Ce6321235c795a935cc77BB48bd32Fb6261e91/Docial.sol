// SPDX-License-Identifier: MIT
// .JJJJJJJJJ7~.        ~J5PGPY7:        ~J5PGPY7:     ?JJJ?      :JJJJJJ?      :JJJJ~
// :@@@@@@@@@@@#?     ^G@@@@@@@@&Y.    ^B@@@@@@@@&?    #@@@#.     7@@@@@@@:     ~@@@@Y
// :&@@@@@@@@@@@@5   ^&@@@@&&@@@@@P   ^&@@@@&&@@@@@J   B@@@B      5@@@@@@@!     ~@@@@Y
// :&@@@G^^^7#@@@@~  5@@@@J:.^G@@@@~  5@@@@J:.^G@@@&:  B@@@B     .B@@@@@@@Y     ~@@@@Y
// :&@@@P    !@@@@?  B@@@#    !@@@@?  G@@@#.   ~@@@@~  B@@@B     ^@@@#B@@@B     ~@@@@Y
// :&@@@P    ~@@@@Y .B@@@B    ~@@@@? .B@@@B    ~@@@@7  B@@@B     7@@@PJ@@@&:    ~@@@@Y
// :&@@@P    ~@@@@Y .B@@@B.   ~@@@@?  B@@@B.   ^BBB#~  B@@@B     P@@@?~@@@@7    ~@@@@Y
// :&@@@P    ~@@@@Y .B@@@B.   ~@@@@?  B@@@B.           B@@@B    .#@@@~.&@@@5    ~@@@@Y
// :&@@@P    ~@@@@Y .B@@@B.   ~@@@@?  B@@@B.           B@@@B    ^@@@&. G@@@B    ~@@@@Y
// :&@@@P    ~@@@@Y .B@@@B.   ~@@@@?  B@@@B.           B@@@B    ?@@@G  Y@@@&^   ~@@@@Y
// :&@@@P    ~@@@@Y .B@@@B.   ~@@@@?  B@@@B.           B@@@B    P@@@Y  !@@@@7   ~@@@@Y
// :&@@@P    ~@@@@Y .B@@@B.   ~@@@@?  B@@@B.           B@@@B   .#@@@!  :&@@@5   ~@@@@Y
// :&@@@P    ~@@@@Y .B@@@B.   ~@@@@?  B@@@B.   :5555^  B@@@B   ^@@@&.   B@@@B.  ~@@@@Y
// :&@@@P    ~@@@@Y .B@@@B.   ~@@@@?  B@@@B.   ~@@@@7  B@@@B   ?@@@&555Y#@@@@^  ~@@@@Y
// :&@@@P    ~@@@@Y .B@@@B    ~@@@@?  B@@@B    ~@@@@!  B@@@B   P@@@@@@@@@@@@@7  ~@@@@Y
// :&@@@P    7@@@@?  B@@@#.   !@@@@?  G@@@#.   !@@@@~  B@@@B. .#@@@&####&@@@@5  ~@@@@J
// :&@@@B!!!?#@@@@~  Y@@@@Y^:~B@@@@~  Y@@@@5^:~B@@@#.  B@@@B. ~@@@&~....:B@@@B. ~@@@@P!!!!!!!:
// :&@@@@@@@@@@@@Y   :#@@@@@&@@@@@5   :#@@@@@@@@@@@?   B@@@B. ?@@@B      5@@@@^ ~@@@@@@@@@@@@7
// :@@@@@@@@@@@B7     :P@@@@@@@@&J     ^P@@@@@@@@#7   .#@@@#  G@@@5      7@@@@? ~@@@@@@@@@@@@7
// .7???????7!^         ^7Y555J!.        ^7Y555J~.     7???7  7???^      :????~ :????????????:
pragma solidity ^0.8.4;

import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

contract Docial is ERC721AUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    uint256 public mintPrice;
    uint256 public maxSupply;
    uint256 public maxMinting;
    uint256 public counterFreeMint;
    uint256 public startTime;
    uint256 public maxMintPerWallet;
    uint256 public maxFreeMintPerWallet;

    function initialize() public initializerERC721A initializer {
        __ERC721A_init("Docial Pass", "DCPS");
        __Ownable_init();
    }

    function adminMint(uint256 quantity) external payable onlyOwner {
        _mint(msg.sender, quantity);
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxSupply(uint256 _setMaxSupply) public onlyOwner {
        maxSupply = _setMaxSupply;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        counterFreeMint = 0;
        startTime = _startTime;
    }

    function setMaxMinting(uint256 _setMaxMinting) public onlyOwner {
        maxMinting = _setMaxMinting;
    }

    function setMaxMintPerWallet(uint256 _maxMintPerWallet) public onlyOwner {
        maxMintPerWallet = _maxMintPerWallet;
    }

    function setmaxFreeMintPerWallet(uint256 _maxFreeMintPerWallet)
        public
        onlyOwner
    {
        maxFreeMintPerWallet = _maxFreeMintPerWallet;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
