//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";
import "./VRFConsumerBase.sol";

/**
                          _____                                                                  
 ______   _______    _____\    \  ______   _____          ________    ________         ____      
|\     \  \      \  /    / |    ||\     \ |     |        /        \  /        \    ____\_  \__   
 \\     \  |     /|/    /  /___/|\ \     \|     |       |\         \/         /|  /     /     \  
  \|     |/     //|    |__ |___|/ \ \           |       | \            /\____/ | /     /\      | 
   |     |_____// |       \        \ \____      |       |  \______/\   \     | ||     |  |     | 
   |     |\     \ |     __/ __      \|___/     /|        \ |      | \   \____|/ |     |  |     | 
  /     /|\|     ||\    \  /  \         /     / |         \|______|  \   \      |     | /     /| 
 /_____/ |/_____/|| \____\/    |       /_____/  /                  \  \___\     |\     \_____/ | 
|     | / |    | || |    |____/|       |     | /                    \ |   |     | \_____\   | /  
|_____|/  |____|/  \|____|   | |       |_____|/                      \|___|      \ |    |___|/   
                         |___|/                                                   \|____|        
                                                        _____                                                                                                   
        _____    ______   _____ ______  ______     _____\    \ ___________                     _____     ____________    ________    ________   ______   _____  
   _____\    \_ |\     \ |     |\     \|\     \   /    / |    |\          \               _____\    \_  /            \  /        \  /        \ |\     \ |     | 
  /     /|     |\ \     \|     | |     |\|     | /    /  /___/| \    /\    \             /     /|     ||\___/\  \\___/||\         \/         /|\ \     \|     | 
 /     / /____/| \ \           | |     |/____ / |    |__ |___|/  |   \_\    |           /     / /____/| \|____\  \___|/| \            /\____/ | \ \           | 
|     | |____|/   \ \____      | |     |\     \ |       \        |      ___/           |     | |____|/        |  |     |  \______/\   \     | |  \ \____      | 
|     |  _____     \|___/     /| |     | |     ||     __/ __     |      \  ____        |     |  _____    __  /   / __   \ |      | \   \____|/    \|___/     /| 
|\     \|\    \        /     / | |     | |     ||\    \  /  \   /     /\ \/    \       |\     \|\    \  /  \/   /_/  |   \|______|  \   \             /     / | 
| \_____\|    |       /_____/  //_____/|/_____/|| \____\/    | /_____/ |\______|       | \_____\|    | |____________/|            \  \___\           /_____/  / 
| |     /____/|       |     | / |    |||     | || |    |____/| |     | | |     |       | |     /____/| |           | /             \ |   |           |     | /  
 \|_____|    ||       |_____|/  |____|/|_____|/  \|____|   | | |_____|/ \|_____|        \|_____|    || |___________|/               \|___|           |_____|/   
        |____|/                                        |___|/                                  |____|/                                                          

*/

contract KeyToCyberCity is ERC721, Ownable, VRFConsumerBase {

    using Strings for uint256;

    struct RevealData {
        uint range;
        uint randomness;
    }

    RevealData[] revealData;

    string[] baseURIs;

    //Chainlink values
    uint constant fee = 2 ether;
    bytes32 constant keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;

    uint constant publicSupply = 800;

    uint constant whitelistSupply = 88;

    uint constant goldenKeyChance = 50; //5% chance

    bool isPublicMint;

    uint publicMinted;

    uint whitelistMinted;

    address YBotsContract;

    mapping(address => bool) publicAddressesMinted;

    mapping(uint => address) public stakedPasses;

    event Staked(address indexed owner, uint indexed tokenId);

    event UnStaked(address indexed owner, uint indexed tokenId);

    constructor(address _vrfCoordinator, address _link) 
        ERC721("Key to Cyber City", "KEY2CITY")
        VRFConsumerBase(_vrfCoordinator, _link)
    {}

    /**
    
            ___________          ____________  _____    _____    ________    ________   
           /           \        /            \|\    \   \    \  /        \  /        \  
          /    _   _    \      |\___/\  \\___/|\\    \   |    ||\         \/         /| 
         /    //   \\    \      \|____\  \___|/ \\    \  |    || \            /\____/ | 
        /    //     \\    \           |  |       \|    \ |    ||  \______/\   \     | | 
       /     \\_____//     \     __  /   / __     |     \|    | \ |      | \   \____|/  
      /       \ ___ /       \   /  \/   /_/  |   /     /\      \ \|______|  \   \       
     /________/|   |\________\ |____________/|  /_____/ /______/|         \  \___\      
    |        | |   | |        ||           | / |      | |     | |          \ |   |      
    |________|/     \|________||___________|/  |______|/|_____|/            \|___|      
                                                                                
    
    */

    function publicMint() external {

        require(isPublicMint, "Minting isn't live");

        require(publicAddressesMinted[msg.sender] == false, "Already minted");

        uint _publicMinted = publicMinted;

        require(_publicMinted < publicSupply, "All Minted");

        unchecked {
            ++_publicMinted;
        }

        publicMinted = _publicMinted; 

        publicAddressesMinted[msg.sender] = true;

        _safeMint(msg.sender, _publicMinted);

    }

    /**
    
            _____    ________    ________      _____         ______   _______    ____________  _____    _____            _____        
       _____\    \  /        \  /        \   /      |_      |\     \  \      \  /            \|\    \   \    \      _____\    \_      
      /    / \    ||\         \/         /| /         \      \\     \  |     /||\___/\  \\___/|\\    \   |    |    /     /|     |     
     |    |  /___/|| \            /\____/ ||     /\    \      \|     |/     //  \|____\  \___|/ \\    \  |    |   /     / /____/|     
  ____\    \ |   |||  \______/\   \     | ||    |  |    \      |     |_____//         |  |       \|    \ |    |  |     | |_____|/     
 /    /\    \|___|/ \ |      | \   \____|/ |     \/      \     |     |\     \    __  /   / __     |     \|    |  |     | |_________   
|    |/ \    \       \|______|  \   \      |\      /\     \   /     /|\|     |  /  \/   /_/  |   /     /\      \ |\     \|\        \  
|\____\ /____/|               \  \___\     | \_____\ \_____\ /_____/ |/_____/| |____________/|  /_____/ /______/|| \_____\|    |\__/| 
| |   ||    | |                \ |   |     | |     | |     ||     | / |    | | |           | / |      | |     | || |     /____/| | || 
 \|___||____|/                  \|___|      \|_____|\|_____||_____|/  |____|/  |___________|/  |______|/|_____|/  \|_____|     |\|_|/ 
                                                                                                                         |____/       
    
    
    */

    function stake(uint[] calldata tokenIds) external {

        uint count = tokenIds.length;
        for(uint i = 0; i < count;) {

            uint tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "User doesn't own this token");

            _burn(tokenId);

            stakedPasses[tokenId] = msg.sender;

            emit Staked(msg.sender, tokenId);

            unchecked {
                ++i;
            }
        }

    }

    function unstake(uint[] calldata tokenIds) external {

        uint count = tokenIds.length;
        for(uint i = 0; i < count;) {

            uint tokenId = tokenIds[i];
            require(stakedPasses[tokenId] == msg.sender, "User doesn't own this token");

            _safeMint(msg.sender, tokenId);

            emit UnStaked(msg.sender, tokenId);

            delete stakedPasses[tokenId];

            unchecked {
                ++i;
            }
        }

    }

    /**
                                                              
    ______  ______ ______   _____    ___________      _____    _____     
    \     \|\     \\     \  \    \   \          \    |\    \   \    \    
    |     |\|     |\    |  |    |    \    /\    \    \\    \   |    |   
    |     |/____ /  |   |  |    |     |   \_\    |    \\    \  |    |   
    |     |\     \  |    \_/   /|     |      ___/      \|    \ |    |   
    |     | |     | |\         \|     |      \  ____    |     \|    |   
    |     | |     | | \         \__  /     /\ \/    \  /     /\      \  
    /_____/|/_____/|  \ \_____/\    \/_____/ |\______| /_____/ /______/| 
    |    |||     | |   \ |    |/___/||     | | |     ||      | |     | | 
    |____|/|_____|/     \|____|   | ||_____|/ \|_____||______|/|_____|/  
                              |___|/                                     
        
    */

    function burnBatch(address owner, uint[] calldata tokenIds) external {

        require(msg.sender == YBotsContract, "Caller not YBots");

        for(uint i = 0; i < tokenIds.length;) {

            burn(owner, tokenIds[i]);

            unchecked {
                ++i;
            }

        }

    }

    function burn(address owner, uint tokenId) internal {

        require(ownerOf(tokenId) == owner, "Not owner");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");

        _burn(tokenId);

    }

     /**                                                                                                                                                      
            _____         __     __           _____          ____________  _____    _____   _____              ____________  _____    _____     ______   _______   
       _____\    \_      /  \   /  \        /      |_       /            \|\    \   \    \ |\    \            /            \|\    \   \    \   |\     \  \      \  
      /     /|     |    /   /| |\   \      /         \     |\___/\  \\___/|\\    \   |    | \\    \          |\___/\  \\___/|\\    \   |    |   \\     \  |     /| 
     /     / /____/|   /   //   \\   \    |     /\    \     \|____\  \___|/ \\    \  |    |  \\    \          \|____\  \___|/ \\    \  |    |    \|     |/     //  
    |     | |____|/   /    \_____/    \   |    |  |    \          |  |       \|    \ |    |   \|    | ______        |  |       \|    \ |    |     |     |_____//   
    |     |  _____   /    /\_____/\    \  |     \/      \    __  /   / __     |     \|    |    |    |/      \  __  /   / __     |     \|    |     |     |\     \   
    |\     \|\    \ /    //\_____/\\    \ |\      /\     \  /  \/   /_/  |   /     /\      \   /            | /  \/   /_/  |   /     /\      \   /     /|\|     |  
    | \_____\|    |/____/ |       | \____\| \_____\ \_____\|____________/|  /_____/ /______/| /_____/\_____/||____________/|  /_____/ /______/| /_____/ |/_____/|  
    | |     /____/||    | |       | |    || |     | |     ||           | / |      | |     | ||      | |    |||           | / |      | |     | ||     | / |    | |  
     \|_____|    |||____|/         \|____| \|_____|\|_____||___________|/  |______|/|_____|/ |______|/|____|/|___________|/  |______|/|_____|/ |_____|/  |____|/   
            |____|/                                                                                                                                                
    
    */

    /**
     * @dev Callback function used by Chainlink VRF Coordinator
    * sets the randomness used to determine the type of each key
    */
    function fulfillRandomness(bytes32, uint256 _randomness) internal override {

       
        revealData[revealData.length - 1].randomness = _randomness;

    }

    /**                                      _____                            
   _______    ______   ____________     _____\    \    _______     _______    
   \      |  |      | /            \   /    / |    |  /      /|   |\      \   
    |     /  /     /||\___/\  \\___/| /    /  /___/| /      / |   | \      \  
    |\    \  \    |/  \|____\  \___|/|    |__ |___|/|      /  |___|  \      | 
    \ \    \ |    |         |  |     |       \      |      |  |   |  |      | 
     \|     \|    |    __  /   / __  |     __/ __   |       \ \   / /       | 
      |\         /|   /  \/   /_/  | |\    \  /  \  |      |\\/   \//|      | 
      | \_______/ |  |____________/| | \____\/    | |\_____\|\_____/|/_____/| 
       \ |     | /   |           | / | |    |____/| | |     | |   | |     | | 
        \|_____|/    |___________|/   \|____|   | |  \|_____|\|___|/|_____|/  
                                            |___|/                   

    */         

    /**
        @dev Returns the key type of the token, type is determined randomly based on chainlinks verifiable random number
    */
    function getKeyType(uint tokenId) public view returns(uint) {
            
        RevealData[] memory data = revealData;

        uint count = data.length;
        uint randomness;
        for(uint i = 0; i < count;) {

            if(tokenId <= data[i].range) {

                randomness = data[i].randomness;
                break;

            }

            unchecked {
                
                ++i; 
            }

        }

        if(randomness == 0) {
            return 0;
        }
            
        uint value = uint(keccak256(abi.encodePacked(tokenId, randomness))) % 1000;

        if(value <= goldenKeyChance) {
            //Golden Key
            return 2;
        }

        return 1;

    }

    /**
    * @dev See {IERC721Metadata-tokenURI}. 
    *  Returns the metadata uri based on the tokens key type
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {

        require(_exists(tokenId), "Token doesn't exist");

        uint passType = getKeyType(tokenId);

        string memory uri = baseURIs[passType];

        return string(abi.encodePacked(uri, tokenId.toString()));
    }


    /**
                                                                       _____                    
           ____        _______     _______   _____    _____       _____\    \ ___________       
       ____\_  \__    /      /|   |\      \ |\    \   \    \     /    / |    |\          \      
      /     /     \  /      / |   | \      \ \\    \   |    |   /    /  /___/| \    /\    \     
     /     /\      ||      /  |___|  \      | \\    \  |    |  |    |__ |___|/  |   \_\    |    
    |     |  |     ||      |  |   |  |      |  \|    \ |    |  |       \        |      ___/     
    |     |  |     ||       \ \   / /       |   |     \|    |  |     __/ __     |      \  ____  
    |     | /     /||      |\\/   \//|      |  /     /\      \ |\    \  /  \   /     /\ \/    \ 
    |\     \_____/ ||\_____\|\_____/|/_____/| /_____/ /______/|| \____\/    | /_____/ |\______| 
    | \_____\   | / | |     | |   | |     | ||      | |     | || |    |____/| |     | | |     | 
     \ |    |___|/   \|_____|\|___|/|_____|/ |______|/|_____|/  \|____|   | | |_____|/ \|_____| 
      \|____|                                                         |___|/                    
   
    */

    function airdropTokens(address[] calldata _addresses) external onlyOwner {

        uint length = _addresses.length;

        uint minted = whitelistMinted;

        require(minted + length <= whitelistSupply, "Minting too many");

        for(uint i = 1; i <= length;) {

            unchecked {
                _mint(_addresses[i - 1], publicSupply + minted + i);
                ++i;
            }

        }

        whitelistMinted += length;

    }

    function setUris(string[] memory _uris) external onlyOwner {

        baseURIs = _uris;

    }
   

    function reveal(uint range) external onlyOwner {

        RevealData[] memory data = revealData;

        if(data.length > 0) {

            require(range > data[data.length - 1].range, "Range needs to be greator than last");
            require(data[data.length - 1].randomness > 0, "randomness needs to be set");
            
        }

        revealData.push(RevealData(range, 0));

        requestRandomness(keyHash, fee);

    }

    function setYBots(address _yBots) external onlyOwner {

        YBotsContract = _yBots;

    }

    function setPublicMint(bool _value) external onlyOwner {

        isPublicMint = _value;

    }

}
