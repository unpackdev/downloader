// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract BirdHouseBuddies is ERC721Enumerable, Ownable {
/*
 _____ _  _ ___   ___ ___ ___ ___  _  _  ___  _   _ ___ ___    ___ ___  __  __ ___  _   _  _ ___ ___  _  _ ___ 
|_   _| || | __| | _ )_ _| _ \   \| || |/ _ \| | | / __| __|  / __/ _ \|  \/  | _ \/_\ | \| |_ _/ _ \| \| / __|
  | | | __ | _|  | _ \| ||   / |) | __ | (_) | |_| \__ \ _|  | (_| (_) | |\/| |  _/ _ \| .` || | (_) | .` \__ \
  |_| |_||_|___| |___/___|_|_\___/|_||_|\___/ \___/|___/___|  \___\___/|_|  |_|_|/_/ \_\_|\_|___\___/|_|\_|___/                                                                                                                                                               
*/

/*
__   ___   ___   ___  ___ ___ _      _   ___    _ _____ ___ ___  _  _ ___ 
\ \ / /_\ | _ \ |   \| __/ __| |    /_\ | _ \  /_\_   _|_ _/ _ \| \| / __|
 \ V / _ \|   / | |) | _| (__| |__ / _ \|   / / _ \| |  | | (_) | .` \__ \
  \_/_/ \_\_|_\ |___/|___\___|____/_/ \_\_|_\/_/ \_\_| |___\___/|_|\_|___/                                                                         
*/

    IERC721Enumerable private TheBirdHouseContract;

    //uint256's
    uint256 public originalSupply = 6000;
    uint256 public maxSupply = 12000;
    bool public saleLive = false;

    //strings
    string public contractURI = "ipfs://QmcQSsXhohgN547KmVZSbH8v17Q6dQFj1ayYP2PBqdX8fA";
    string public baseURI = "";
    string public PROVENANCE_HASH = "406f9d03f776bd094f59dd2b82445df9";

    //bools
    bool public baseURIChangeable = true;

    //Libraries
    using Strings for uint256;

    //Addresses
    address public TheBirdHouseAddress;

    //
    bool public isRevealed = false;
    string public unrevealedURI = "ipfs://QmQCsJJ63a1D6BQtWcyKh3EdzPWsq7XfxrmAK3Hsfj96R4";

    constructor(address theBirdHouseAddress)
        ERC721("BirdHouseBuddies", "BUDDY")
    {
        TheBirdHouseAddress = theBirdHouseAddress;
        TheBirdHouseContract = IERC721Enumerable(theBirdHouseAddress);
    }

    /*
 _   _ ___ ___ ___  __      _____ ___ _____ ___   ___ _   _ _  _  ___ _____ ___ ___  _  _ ___ 
| | | / __| __| _ \ \ \    / / _ \_ _|_   _| __| | __| | | | \| |/ __|_   _|_ _/ _ \| \| / __|
| |_| \__ \ _||   /  \ \/\/ /|   /| |  | | | _|  | _|| |_| | .` | (__  | |  | | (_) | .` \__ \
 \___/|___/___|_|_\   \_/\_/ |_|_\___| |_| |___| |_|  \___/|_|\_|\___| |_| |___\___/|_|\_|___/
                                                                                              
*/

    function burnBirds(uint256[] memory birdIds) public {
        require(saleLive == true, "Sale must be live!");
        require(
            birdIds.length > 0 && birdIds.length <= 50,
            "Can only burn between 0 and 50 birds!"
        );

        for (uint256 i = 0; i < birdIds.length; i++) {
            uint256 birdId = birdIds[i];
            uint256 newCompanionId = birdId + originalSupply;

            require(newCompanionId < maxSupply, "Companion ID too high!");
            require(birdId < originalSupply, "birdId too high!");
            require(
                TheBirdHouseContract.ownerOf(birdId) == msg.sender,
                "You must own the same bird Id!"
            );
            require(
                TheBirdHouseContract.isApprovedForAll(
                    msg.sender,
                    TheBirdHouseAddress
                ) == true,
                "You must approve The BirdHouse contract to burn your birds."
            );

            TheBirdHouseContract.transferFrom(
                msg.sender,
                0x0000000000000000000000000000000000000DeD,
                birdId
            );

            _safeMint(msg.sender, newCompanionId);
        }
    }

    function claimCompanionsById(uint256[] memory birdIds) public {
        require(saleLive == true, "Sale must be live!");
        require(
            birdIds.length > 0 && birdIds.length <= 50,
            "Can only claim between 0 and 50 birds!"
        );

        for (uint256 i = 0; i < birdIds.length; i++) {
            uint256 birdId = birdIds[i];

            require(birdId < originalSupply, "CompanionId too high!");
            require(
                TheBirdHouseContract.ownerOf(birdId) == msg.sender,
                "You must own the same bird Id!"
            );

            if (!_exists(birdId)) {
                //This doesn't exist, so mint it to them!
                _safeMint(msg.sender, birdId);
            }
        }
    }

    function claimCompanionsByCountAndStartingIndex(
        uint256 companionCount,
        uint256 startingBirdIndex
    ) public {
        require(saleLive == true, "Sale must be live!");
        require(
            companionCount > 0 && companionCount <= 50,
            "Must claim between 1 and 50 companions"
        );

        uint256 birdBalance = TheBirdHouseContract.balanceOf(msg.sender);
        //This is the balance of birds within the main contract.

        require(birdBalance > 0, "Must hold at least one bird!");
        //Must have at least one OG bird.

        //Your balance of OG birds must be equal or higher that the amount of companions you are requesting
        require(
            birdBalance >= startingBirdIndex + companionCount,
            "Can't claim more companions than birds!"
        );

        for (uint256 i = 0; i < birdBalance && i < companionCount; i++) {
            uint256 tokenId = TheBirdHouseContract.tokenOfOwnerByIndex(
                msg.sender,
                i + startingBirdIndex
            );

            if (!_exists(tokenId)) {
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    /*
  _____      ___  _ ___ ___  __      _____ ___ _____ ___   ___ _   _ _  _  ___ _____ ___ ___  _  _ ___ 
 / _ \ \    / / \| | __| _ \ \ \    / / _ \_ _|_   _| __| | __| | | | \| |/ __|_   _|_ _/ _ \| \| / __|
| (_) \ \/\/ /| .` | _||   /  \ \/\/ /|   /| |  | | | _|  | _|| |_| | .` | (__  | |  | | (_) | .` \__ \
 \___/ \_/\_/ |_|\_|___|_|_\   \_/\_/ |_|_\___| |_| |___| |_|  \___/|_|\_|\___| |_| |___\___/|_|\_|___/
                                                                                                       
*/

    function setRevealData(bool _isRevealed, string memory _unrevealedURI) public onlyOwner {
        isRevealed = _isRevealed;
        unrevealedURI = _unrevealedURI;
    }

    function setSaleState(bool newSaleState) public onlyOwner {
        saleLive = newSaleState;
    }

    function changeContractURI(string memory newContractURI)
        public
        onlyOwner
        returns (string memory)
    {
        contractURI = newContractURI;
        return (contractURI);
    }

    function makeBaseURINotChangeable() public onlyOwner returns (bool) {
        baseURIChangeable = false;
        return baseURIChangeable;
    }

    function changeBaseURI(string memory newBaseURI)
        public
        onlyOwner
        returns (string memory)
    {
        require(
            baseURIChangeable == true,
            "Base URI is currently not changeable"
        );
        baseURI = newBaseURI;
        return baseURI;
    }

    /*
 ___ ___   _   ___    ___ _   _ _  _  ___ _____ ___ ___  _  _ ___ 
| _ \ __| /_\ |   \  | __| | | | \| |/ __|_   _|_ _/ _ \| \| / __|
|   / _| / _ \| |) | | _|| |_| | .` | (__  | |  | | (_) | .` \__ \
|_|_\___/_/ \_\___/  |_|  \___/|_|\_|\___| |_| |___\___/|_|\_|___/
    */

    function isClaimed(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent companion"
        );

        if(isRevealed){
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        } else {
            return unrevealedURI;
        }
    }
}
