//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./ERC721A.sol";

/*
HarukaToken.sol

Contract by @NftDoyler
*/

contract HarukaToken is Initializable, ERC20BurnableUpgradeable, OwnableUpgradeable {
    // Note: Values cannot be hard-coded when using an upgradeable contract.
    uint256 public emissionRate;

    uint256 public emissionStart;

    // Address for Haruka Ronin NFTs
    address public harukaRonin;

    // Note: Another option is to inherit Pausable without implementing the logic yourself.
        // That said, it costs about 3.6% more gas over this basic implementation.
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
    bool public paused;

    struct TokenEmissions {
        // When this tokenId last claimed $haruka
            // Note: This will technically overflow in 2106
        uint32 lastClaimed;

        // This is just a modifier on the base 100/day
            // This means that 5 here = 500 $haruka/day
            // Based on the original medium article - https://medium.com/@harukaronin/haruka-tokenomics-and-plan-dfb895b08f1f
            // Epic is 200 $haruka/day, Legendary is 1000 $haruka/day
        uint8 emissionModifier;

        // Whether or not this token has been used to "claim" a chibi
        bool claimedChibi;

        // Whether or not this token has been shipped their chibi
        bool shippedChibi;
    }

    mapping(uint256 => TokenEmissions) private tokens;

    //constructor() ERC20("HarukaToken", "HARUKA") { }
    function initialize(string memory _name, string memory _symbol) public virtual initializer {
        __ERC20_init(_name, _symbol);
        //_mint(_msgSender(), initialSupply);
        
        // Initialize ownership
        __Ownable_init();

        // This is ROUGHLY 100 $haruka/day
        emissionRate = uint(100 * (10 ** 18)) / 86400;
        
        // 24 April 2022 @ 12:00:00 GMT
        emissionStart = 1650758400;
        paused = true;
    }

    /*
     *

    $$$$$$$\            $$\                      $$\                     $$$$$$$$\                              $$\     $$\                               
    $$  __$$\           \__|                     $$ |                    $$  _____|                             $$ |    \__|                              
    $$ |  $$ | $$$$$$\  $$\ $$\    $$\ $$$$$$\ $$$$$$\    $$$$$$\        $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    $$$$$$$  |$$  __$$\ $$ |\$$\  $$  |\____$$\\_$$  _|  $$  __$$\       $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$  ____/ $$ |  \__|$$ | \$$\$$  / $$$$$$$ | $$ |    $$$$$$$$ |      $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
    $$ |      $$ |      $$ |  \$$$  / $$  __$$ | $$ |$$\ $$   ____|      $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
    $$ |      $$ |      $$ |   \$  /  \$$$$$$$ | \$$$$  |\$$$$$$$\       $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
    \__|      \__|      \__|    \_/    \_______|  \____/  \_______|      \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 
                                                                                                                                                      
    *
    */

    /*
     *

    $$$$$$$\            $$\       $$\ $$\                 $$$$$$$$\                              $$\     $$\                               
    $$  __$$\           $$ |      $$ |\__|                $$  _____|                             $$ |    \__|                              
    $$ |  $$ |$$\   $$\ $$$$$$$\  $$ |$$\  $$$$$$$\       $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    $$$$$$$  |$$ |  $$ |$$  __$$\ $$ |$$ |$$  _____|      $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$  ____/ $$ |  $$ |$$ |  $$ |$$ |$$ |$$ /            $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
    $$ |      $$ |  $$ |$$ |  $$ |$$ |$$ |$$ |            $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
    $$ |      \$$$$$$  |$$$$$$$  |$$ |$$ |\$$$$$$$\       $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
    \__|       \______/ \_______/ \__|\__| \_______|      \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 

    *
    */

    function claim(uint256[] memory _tokenIds) public noPauseNoContract() {        
        uint256 rewards = 0;

        for (uint i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(ERC721A(harukaRonin).ownerOf(tokenId) == msg.sender, "Not your token");

            uint256 lastClaimed = tokens[tokenId].lastClaimed;
            uint256 modifiedRate = (tokens[tokenId].emissionModifier == 0 ? 1 : tokens[tokenId].emissionModifier) * emissionRate;

            // Note: It would actually increase gas by 7.5% if we called getRewardsForId
            rewards += (block.timestamp - (lastClaimed == 0 ? emissionStart : lastClaimed)) * modifiedRate;
            
            tokens[tokenId].lastClaimed = uint32(block.timestamp);
        }

        _mint(msg.sender, rewards);
    }    

    /*
     *

    $$\    $$\ $$\                               $$$$$$$$\                              $$\     $$\                               
    $$ |   $$ |\__|                              $$  _____|                             $$ |    \__|                              
    $$ |   $$ |$$\  $$$$$$\  $$\  $$\  $$\       $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    \$$\  $$  |$$ |$$  __$$\ $$ | $$ | $$ |      $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
     \$$\$$  / $$ |$$$$$$$$ |$$ | $$ | $$ |      $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
      \$$$  /  $$ |$$   ____|$$ | $$ | $$ |      $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
       \$  /   $$ |\$$$$$$$\ \$$$$$\$$$$  |      $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
        \_/    \__| \_______| \_____\____/       \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 

    *
    */

    function getRewardsForId(uint256 _id) public view returns (uint) {
        uint256 lastClaimed = tokens[_id].lastClaimed;
        uint256 modifiedRate = (tokens[_id].emissionModifier == 0 ? 1 : tokens[_id].emissionModifier) * emissionRate;

        return (block.timestamp - (lastClaimed == 0 ? emissionStart : lastClaimed)) * modifiedRate;
    }

    /*
     *

     $$$$$$\                                                    $$$$$$$$\                              $$\     $$\                               
    $$  __$$\                                                   $$  _____|                             $$ |    \__|                              
    $$ /  $$ |$$\  $$\  $$\ $$$$$$$\   $$$$$$\   $$$$$$\        $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    $$ |  $$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\ $$  __$$\       $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$ |  $$ |$$ | $$ | $$ |$$ |  $$ |$$$$$$$$ |$$ |  \__|      $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
    $$ |  $$ |$$ | $$ | $$ |$$ |  $$ |$$   ____|$$ |            $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
     $$$$$$  |\$$$$$\$$$$  |$$ |  $$ |\$$$$$$$\ $$ |            $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
     \______/  \_____\____/ \__|  \__| \_______|\__|            \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 

     *
     */

    function setHarukaAddress(address _address) external onlyOwner {
        harukaRonin = _address;
    }

    // Update the emission start and base rate. This shouldn't be needed.
    function setInitialEmissions(uint256 _start, uint256 _rate) external onlyOwner {
        emissionStart = _start;
        emissionRate = _rate;
    }

    // Increase (or decrease) the emissions for an array of tokenIds
    function setIncreasedEmissions(uint256[] memory _tokenIds, uint8 _rate) external onlyOwner {
        for (uint i; i < _tokenIds.length; i++) {
            tokens[_tokenIds[i]].emissionModifier = uint8(_rate);
        }
    }

    function setClaimedChibi(uint256 _tokenId, bool _isClaimed) external onlyOwner {
        tokens[_tokenId].claimedChibi = _isClaimed;
    }

    function setShippedChibi(uint256 _tokenId, bool _isShipped) external onlyOwner {
        tokens[_tokenId].shippedChibi = _isShipped;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function ownerMint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function ownerBurn(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }

    /*
     *

    $$\      $$\                 $$\ $$\  $$$$$$\  $$\                               
    $$$\    $$$ |                $$ |\__|$$  __$$\ \__|                              
    $$$$\  $$$$ | $$$$$$\   $$$$$$$ |$$\ $$ /  \__|$$\  $$$$$$\   $$$$$$\   $$$$$$$\ 
    $$\$$\$$ $$ |$$  __$$\ $$  __$$ |$$ |$$$$\     $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$ \$$$  $$ |$$ /  $$ |$$ /  $$ |$$ |$$  _|    $$ |$$$$$$$$ |$$ |  \__|\$$$$$$\  
    $$ |\$  /$$ |$$ |  $$ |$$ |  $$ |$$ |$$ |      $$ |$$   ____|$$ |       \____$$\ 
    $$ | \_/ $$ |\$$$$$$  |\$$$$$$$ |$$ |$$ |      $$ |\$$$$$$$\ $$ |      $$$$$$$  |
    \__|     \__| \______/  \_______|\__|\__|      \__| \_______|\__|      \_______/ 

    *
    */

    modifier noPauseNoContract() {
        require(!paused, "Contract is paused");
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}