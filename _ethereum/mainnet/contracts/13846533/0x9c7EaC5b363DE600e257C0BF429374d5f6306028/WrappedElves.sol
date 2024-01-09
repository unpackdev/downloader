//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

/*

--> https://welf.xyz <--

HAPPY HOLIDAYS FROM GENERALGALACTIC.ETH !!

888       8888888888b.        d88888888888b. 8888888b. 88888888888888888b.
888   o   888888   Y88b      d88888888   Y88b888   Y88b888       888  "Y88b
888  d8b  888888    888     d88P888888    888888    888888       888    888
888 d888b 888888   d88P    d88P 888888   d88P888   d88P8888888   888    888
888d88888b8888888888P"    d88P  8888888888P" 8888888P" 888       888    888
88888P Y88888888 T88b    d88P   888888       888       888       888    888
8888P   Y8888888  T88b  d8888888888888       888       888       888  .d88P
888P     Y888888   T88bd88P     888888       888       88888888888888888P"

8888888888888   888     8888888888888 .d8888b.
888       888   888     888888       d88P  Y88b
888       888   888     888888       Y88b.
8888888   888   Y88b   d88P8888888    "Y888b.
888       888    Y88b d88P 888           "Y88b.
888       888     Y88o88P  888             "888
888       888      Y888P   888       Y88b  d88P
888888888888888888  Y8P    8888888888 "Y8888P"

                 .-.
                .;;\ |
               /::::\|\
              /::::'();
             |::::'   |
            |\/`\:_/`\/|
        ,__ |0_..().._0| __,
         \,`////""""\\\\`,/    MERRY CHRISTMAS YA FILTHY ANIMALS!!!
         | )//_ o  o _\\( |  /
          \/|(_) () (_)|\/
            \   '--'   /
            _:.______.;_
          /| | /`\/`\ | |\
         / | | \_/\_/ | | \
        /  |o`""""""""`o|  \
       `.__/     ()     \__.'
       /  /              \  \
       |  | ___  ()  ___ |  |
       /  \|---|    |---|/  \
       |  (|   | () |   |)  |
       \  /;---'    '---;\  /
        `` \ ___ /\ ___ / ``
            `|  |  |  |`
             |  |  |  |
             | =|  |= |
      jgs    |  |  |  |
       _._  |\|\/||\/|/|  _._
      / .-\ |~~~~||~~~~| /-. \
      | \__.'    ||    '.__/ |
      \          ||          /
       `---------''---------`
*/

import "./base64.sol";
import "./ERC721.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./console.sol";
import "./HexStrings.sol";
import "./SVGBuilder.sol";

abstract contract NFTContract {
    function balanceOf(address owner) external view virtual returns (uint256);
}

contract WrappedElves is ERC721, Ownable, PaymentSplitter {
    using Strings for uint256;
    using HexStrings for uint160;
    uint256 public nextTokenID;
    uint256 public burnCount;
    mapping(uint256 => bool) private unwrappedState;
    uint256 public constant elfPrice = 40000000000000000;
    uint256 public constant maxElfId = 499; // 0 -> 499 = 500 elves
    string private baseURI =
        "https://ggc.mypinata.cloud/ipfs/QmdZDwM4E78ykRwgPZReKhoQs9UjyMQR25eojQJhXbneu6/";
    address private immutable floppyAddress;

    constructor(
        address _floppyAddress,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721("WrappedElves", "wELF") PaymentSplitter(_payees, _shares) {
        floppyAddress = _floppyAddress;
    }

    function isUnwrapped(uint256 id) public view returns (bool) {
        return unwrappedState[id];
    }

    function setBaseURI(string memory URI) public onlyOwner {
        baseURI = URI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint() public payable {
        uint256 walletOwns = balanceOf(msg.sender);
        require(elfPrice == msg.value, "Ether value sent is not correct");
        require(walletOwns == 0, "You already own an elf!");
        require(nextTokenID < maxElfId, "We're maxed out on elves");
        uint256 tokenID = nextTokenID;
        _mint(msg.sender, tokenID);
        nextTokenID += 1;
    }

    function magicGift(address[] calldata receivers) external onlyOwner {
        require(
            (nextTokenID + receivers.length) < maxElfId + 1,
            "We're maxed out on elves"
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 tokenID = nextTokenID;
            _mint(receivers[i], tokenID);
            nextTokenID += 1;
        }
    }

    function unwrap(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You dont own this elf");
        unwrappedState[tokenId] = true;
    }

    function wrap(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You dont own this elf");
        unwrappedState[tokenId] = false;
    }

    // Burning elves is hard cos we dont have a mapping from tokenID -> owner
    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
        burnCount += 1;
    }

    function totalSupply() public view returns (uint256) {
        return nextTokenID - burnCount;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token doesn't exist.");
        return unwrappedState[id] ? unwrappedURI(id) : wrappedURI(id);
    }

    function ownedTokens(address owner) public view returns (uint256[] memory) {
        // because the max count is so low, we can be inefficient on this read.
        uint256 countOwnedTokens = balanceOf(owner);
        uint256[] memory _ownedTokens = new uint256[](countOwnedTokens);
        uint256 retIdx = 0;

        //short circuit if there are none owned
        if (countOwnedTokens == 0) {
            return _ownedTokens;
        }

        for (uint256 i = 0; i < nextTokenID; i++) {
            if (ownerOf(i) == owner) {
                _ownedTokens[retIdx] = i;
                retIdx++;
            }
        }
        return _ownedTokens;
    }

    function wrappedURI(uint256 id) internal view returns (string memory) {
        require(_exists(id), "Non-existent Elf");
        address owner = ownerOf(id);
        NFTContract floppyDiskContract = NFTContract(floppyAddress);
        uint256 numFloppies = floppyDiskContract.balanceOf(owner);
        bool hasFloppies;
        if (numFloppies > 0) {
            hasFloppies = true;
        }
        string memory image = Base64.encode(
            bytes(SVGBuilder.makeBox(hasFloppies))
        );
        string
            memory description = "There was an accident at Santas Workshop, and 500 elves got trapped in presents! Help save them before they suffocate!\\n\\n"
            "Please visit https://welf.xyz to unwrap\\n\\n"
            "----\\n\\n"
            "Wrapped Elves is 500 fantastic elves hand-drawn by our wonderful friend, Shawn Smith (aka Shawnimals).\\n\\n"
            "Wrapped Elves are a pun-tastic holiday treat from the fine folks at General Galactic Corporation!\\n\\n"
            "Wrapped elves have two states: Wrapped Elves (wElf) and Unwrapped Elves. The wrapped elves are SVG on-chain packages that have an elf in them. To mint an elf, you need to participate in welf creation. To unwrap an elf, you will need to go to the welf management portal and unwrap it.\\n\\n"
            "If you have a wrapped elf, you must go to welf.xyz and unwrap it. Once your wELF is unwrapped, you will be able to see your wonderful elf, learn its name.";
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                string(
                                    abi.encodePacked(
                                        "Wrapped Elf #",
                                        id.toString()
                                    )
                                ),
                                '", "description":"',
                                description,
                                '", "external_url":"https://welf.xyz/?id=',
                                id.toString(),
                                '", "attributes": [], "owner":"',
                                uint160(owner).toHexString(20),
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function unwrappedURI(uint256 id) internal view returns (string memory) {
        require(_exists(id), "Non-existent Elf");
        return string(abi.encodePacked(_baseURI(), id.toString()));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        // require(
        //     unwrappedState[tokenId] == false,
        //     "PUT THE ELF BACK IN THE BOX!! (call the wrap function first)"
        // );
        _transfer(from, to, tokenId);
    }
}
