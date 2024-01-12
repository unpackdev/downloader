//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./IERC2981.sol";
import "./ERC721ASGakuen.sol";

//
//
//                                              [Note from Dev]
//                                         PRAISE THE KAORI-CHAN!!!!!
//
//                                                .::-----:::.
//                                         :=+#%%%@@@@@%%%#####*+=-.
//                                .-===-=#@@@@@@@@@@@%%###########***=-.
//                             -+*#******#######%@@@%#####%##########***+-
//                          -*##%###*********#***##%%@###**#%%%########***#=
//                       .+%%%@@###########%@@######*##%*##***#@%########**%#-
//                     :*@@@@@%%@@@@@@@@@@@@@@@#%@@%##########**#@%#########%#*:
//                    *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%############%@%########%##=
//                  -@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%@@%%####%@%#%#####%##=
//                 +@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@#*%@@@%%%%%@@%%%%##@###+
//              .+@@@@@@@@@@@@@@@@@@@@@#*@@@@@@@@@@@@@@@@@@@#*@@@@@%%%%@@@%%%%%@%%#+
//             =%*@@@@@@@@@@@@@@@@@@@@+:#@@@@@@@@@@@@@@@@@@@@#*@@@@@@@%%@@@@@%%@%%%%-
//           .++*%@@@@@@@@@@@@@@@@@@@=:.%@@@@@@@@@@@@@%@@@@@@@%%@@@#%@@%@@@@@@@@@%%%#
//          .-.**@@@@@@@@@@@@@@@@@@@=.  %@@@@@@@@@@@@@@%%@@@@@@@@%:=%@@@%@@@@@@@@@@@%+
//          - +*#%@@@@@@@@@@@@@@@@@+    %@@@@@@@@@@@@@@@@%=-=+*%#:*@@@@@@%@@@@@@@@@@@%.
//         .:.-*#%@@@@@@*@@@@@@@@@*     #@*+@@@@@%@@@@@@@@@@@%#-=%%#%@@@@@@@@@@@@@@@@@+
//         . :.#*%@@@@@##@@@@@@@@%      +@%+%%@@@@#%@@@@@@@@@#:#@@@@@**@@@@@@@@@%@@@@@%
//         .=  %+%@@@@@*@@@@@@#@@:      -@@#@@@@@@@%@@@@@@@@=+#@@@%%@@%#@@@@@@@@%%@@@@@:
//         := :@*@@@@@@@@@+@@*-@*       .#@@@@@@@@@@@@@@@@@#%@@@@@%=#+.*@@@%@@@@**@@@@@-
//         .: +@%%@@@@@@@=-@@:-@:        -@%@@@@@@*@@@@@@@@@@#===+*#:=%@@@@#@@@%::@@@@@+
//         .  +@@@@@@@@@=. =+  *         .=**@@%@@#*@@@@@@@@@@@@@%*:#%#%%@@+#@@+-.#@@@@*
//         ...-#@@@@@@@%.:. .             .--:*#+%@-:*@@@@@@@@@@@+-@@@@@%+#=+@%=++*@@@@#
//          .. :*@@@@@@#@@##%+:              .    :=. .=*%@@@@@*=#%@@@@@#@@-#@%####@@@@%
//          .. ..=#@@@@+%: #@@@#.                 .....  .:%@@@#@@@@@#@#@@#-@@@@@@%@@@@%
//           -  .:.*@@@+.. #@@*@@:             -#@@@@@@#@@=**#@@@@%#+*@@@@-*@@@@@@@@@@@@
//                :*@%@+.  -@@@@#             :%:+@@@:@@**#@*+@@@@#*#@@@@+-@%@@@@@@@@@@%
//                 .*%%-   .-++-                 +@@@*@@= +-:@@@@@@@@@@@*=:*%@@@@@@@@@@*
//                 .*-%+.                        .#@@@#:   .+*@@@@@@@@@%**.+@@@@@@@@@@@-
//                 %#%@:                          ...      .+@@@@@@%*@@* --%@@@@@@@@@@*.
//                #@%@@-                                  =%#@@@@@..**::.=+@@@@@@@@@@%=
//               :@-#@@+                                 :. :@@@@%.-=+:=*#@@@@@@@@@@%*=
//               *= +@%+-                                  .+@@@@*+.=#+=+@@@@@@@@@@@%%-
//               #  :%* .=.                               -#%@@@%##%+=+%@@@@@@@@@@@@@#
//               +   =- +@%-     .=---:.                -*%#%@@#*==*+@@@@@@@@@@@@@@@@.
//               =   *=*+-. =: .+-  -+              .---.#%%@@%#+=*#%@@@@@@@@@@@@@@@-
//                * :=  .  . =%#:   =-          :---:....@@@@%%##%@@@@@@@@@@@@@@@@@=
//                 -..    ::.=@++:. #      :-=++-. ......@@@@@%%@@@@@@@@@@@@@@@@@%:
//                       -:::-*#+=+*=.::+%%*=-.     . .:----+%%@@@#*@@@@@#+=#@%*=.
//                                      =#-.        .:. :   . ==-. . ::.   .:.
//                                      -:               .
//                                      :                :
//                                      :                =.           ... .
//                                      -                 =..:::::...:..  .=+.
//                                     :.                 ::.::..:==:       -%+
//                                    :-               .--:::-:-+%*.         -%#
//                                 .:--              .=%%%##*-:#@*            +%=
//                              .::.              ..+%%%@@@*..+@@+##:         :%%
//                -=++*##%@%-               .....:+%%*##%#- .*@@@@+-.         :*@=
//               :#######+==-.           ...   -*@%+*++::   +@@@@+===.    ..:.:-#%
//               -=+++=*+--::-=:     ..     :+@@@@+=:::    =%@@@@#+++-.:::::::::-
//               :::::::...  .:-         .=%@@@@@#-.   .  .#@@@@+===-:::........:
//               .... .      :+#%+:   .:=*%@@@#=:.-.      =@@@#=:..             :
//             .     ..    .-+*##**=+#%@@@@@*--+%@-     .=+@%-                 -
//             :    ::...::-=*#%%%%%%@@@@@@##@@@%.      =#+@=                 .-
//        .    :. :-::::::-===+++*%%###%@@@@@%*-        #%@@.                 :.
//         ... -:==-::.. .:--=--=+**#%%%%%#*-.         .#@@%                 .-
//           .-+==-.    .:-----=*+===++*=-.             @@@-                .::
//           +=-:          .:-=-:.:---..               :@@#                 .=
//         :-:.            ..   .:..                   -@@.                ..-
//
//
//  @@@@@%+@@@@@-@@@@%#: =%@@@#-           -#@@@%+  -@@@@#  %@@--@@#.@@%.%@@:+@@@@@.*%%- %%#
// .=*@@@:%@@*==+@@+:@@#*@@#-@@@-@@#-+#@@#:@@@.@@@: %@@@@# .@@%-@@# +@@.:@@@ %@*==+ @@@#-@@+
//  .@@@-.%@#=- %@#*=#@=@@@-+@@* *@@--@@* *@@* === =@@.@@# =@@*%@#  %@@:=@@*.%@#=- -@@@@#@@:
// .@@@- +@@@@#.@@@@@@*-@@@ %@@-  =@@@@+  @@@ @@@#.@@@:@@# #@@@@@+ .@@@.=@@-+@@@@#.*@@%@@@@
//.@@@=  #@#=  =@@%:@@%*@@*:@@@  .%@--@%::@@@  %@=*@@@@@@#.@@%-%@% =@@%:%@@ #@#=   @@#+@@@+
//%@@@@@-@@@@@+%@@==@@++@@%%@@- :@@#-+#@@+@@@@@@@-@@@:*@@*=@@=.*%@.=@@@@@@--@@@@@+-@@=:@@@:
//
//
/// @title 0xGakuen Genesis NFT smart contact
/// @author Comet, JayB
contract ZeroXGakuenGenesis is ERC721ASGakuen, Ownable, ReentrancyGuard {
    string private baseURI;
    bool private hasExtention;

    // Compiler will pack it into uint256
    struct SaleConfig {
        // [uint32 for time]
        // Maximum value of uint32 == 4294967295 > Feb 07th, 2106
        // Therefore, Impossible to overflow
        uint32 startTime;
        uint32 endTime;
        // default == NOTSALE
        // claim period == ONSALE
        // IF phase == ONSALE
        // THEN phase = ONSALE | FREECLAIM_MASK_BIT
        //
        // YOU SHOULD SET CLAIM MASK >= 0b'10 to prevent over/underflow
        //
        bytes32 merkleRoot;
        // personalLimit have effect only on pulbic sale.
        // claim limit is always 1
        uint8  personalLimit;
        // mintableleft keeps track of how many NFT are left.
        // Do not need to keep total limit.
        uint16 totalPurchased;
    }

    SaleConfig public _saleConfig;

    // To minimize gas cost, set mint price as default value
    // there is only small chance to change price between deploy and minting
    uint256 public salePrice = 0.05 ether;
    uint256 public totalLimit = 51;

    // purchasedInfo : keep track of user mint / claim.
    // right 3bit keeps track of pulbic mint.
    // other bits keeps track of weather user claimed on this phase or not
    mapping(address => uint256) public purchasedInfo;

    // IERC-2981 royalty info in percent, decimal
    uint256 public royaltyRatio = 5;

    constructor() ERC721ASGakuen("0xGakuGenesis", "ZXGG") {}

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Contract call from another contract is not allowed"
        );
        _;
    }

    /// @notice Mint additional NFT for owner
    /// @dev use it for marketing, etc.
    /// @param numOfTokens NFTs will be minted to owner
    function ownerMint(uint256 numOfTokens) external payable onlyOwner {
        _mint(msg.sender, numOfTokens);
    }

    /// @notice claim Mint
    /// @dev merkleProof should be calculated on frontend to prevent gas.
    /// @dev frontend would submit the merkleProof based on user addr
    /// @param merkleProof is proof calculated on frontend
    function claimMint(bytes32[] memory merkleProof)
        external
        payable
        nonReentrant
        callerIsUser
    {
        SaleConfig memory saleConfig = _saleConfig;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, saleConfig.merkleRoot, leaf),
            "Not listed"
        );

        uint256 currentTime = block.timestamp;
        uint256 startTime = saleConfig.startTime;
        uint256 endTime = saleConfig.endTime;

        require(
            startTime != 0 &&
                currentTime >= startTime &&
                currentTime < endTime,
            "Out of claim period"
        );

        /*
         * They cannot claim over the total limit
         * because we will set merkletree not to exceed total limit.
         * So we do not need to check total limit
         */

        uint256 purchased = purchasedInfo[msg.sender];
        require(purchased == 0, "Already claimed");
        
        require(
            msg.value >= salePrice,
            "ETH is not sufficient"
        );

        purchasedInfo[msg.sender] = 1;
        _saleConfig.totalPurchased++;
        _mint(msg.sender, 1);
    }

    /// @notice change the totalLimit
    /// @param _totalLimit totalLimit will be set to it
    function setTotalLimit(uint256 _totalLimit)
        external
        onlyOwner
    {
      totalLimit = _totalLimit;
    }
    /// @notice change the price
    /// @param _salePrice salePrice will be set to it
    function setPrice(uint256 _salePrice)
        external
        onlyOwner
    {
        salePrice = _salePrice;
    }

    /// @notice Set Whitelist Sale time&price
    /// @dev only checks fundamental requirements
    /// @dev not to make mistake, calculate time&price before call the function
    /// @param _tStart is timestamp when sale starts (second)
    /// @param _tEnd is timestamp when sale ends (second)
    /// @param _personalLimit is individual mint amount limit
    function setSaleConfig(
        uint32  _tStart,
        uint32  _tEnd,
        bytes32 _merkleRoot,
        uint8   _personalLimit
    ) external onlyOwner {
        SaleConfig memory saleConfig = _saleConfig;
        saleConfig.startTime = _tStart;
        saleConfig.endTime = _tEnd;
        saleConfig.merkleRoot = _merkleRoot;
        saleConfig.personalLimit = _personalLimit;

        _saleConfig = saleConfig;
    }

    function getSaleConfig() external view returns(uint256 startTime, uint256 endTime, uint256 personalLimit, uint256 totalPurchased) {
      startTime = uint256(_saleConfig.startTime);
      endTime = uint256(_saleConfig.endTime);
      personalLimit = uint256(_saleConfig.personalLimit);
      totalPurchased = uint256(_saleConfig.totalPurchased);
    }

    /// @dev emergency sale stop
    function finishSale() external onlyOwner {
        SaleConfig memory saleConfig = _saleConfig;
        saleConfig.startTime = 0;
        saleConfig.endTime = 0;
        
        _saleConfig = saleConfig;
    }

    /// @notice Change baseURI
    /// @param _newURI is URI to set
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    /// @notice Change hasExtention
    /// @param _newState is new state to set
    function setHasExtention(bool _newState) external onlyOwner {
        hasExtention= _newState;
    }

    /// @dev override baseURI() in ERC721ASGakuen
    function _baseURI()
        internal
        view
        override(ERC721ASGakuen)
        returns (string memory)
    {
        return baseURI;
    }

    /// @dev override hasExtention() in ERC721ASGakuen
    function _hasExtention()
        internal
        view
        override(ERC721ASGakuen)
        returns (bool)
    {
        return hasExtention;
    }
    
    /// @dev override _startTokenId() in ERC721ASGakuen
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    /// @dev this function will increase the schoolingId, and will reset the whole checkpoint
    /// @dev use this function to start next schooling period
    /// @param _begin _schoolingPolicy.schoolingBegin will be set to it
    /// @param _end _schoolingPolicy.schoolingEnd will be set to it
    /// @param _breaktime _schoolingPolicy.breaktime will be set to it
    function _applyNewSchoolingPolicy(
        uint256 _begin,
        uint256 _end,
        uint256 _breaktime
    ) external onlyOwner {
        _applyNewSchoolingPolicy(
            uint40(_begin),
            uint40(_end),
            uint40(_breaktime)
        );
    }
 
    /// @dev this function change schoolingBegin without increasing the schoolingId
    /// @dev use this function to fix the value set wrong
    /// @param begin _schoolingPolicy.schoolingBegin will be set to it
    function setSchoolingBegin(uint256 begin) external onlyOwner {
        _setSchoolingBegin(uint40(begin));
    }

    /// @dev this function change schoolingEnd without increasing the schoolingId
    /// @dev use this function to fix the value set wrong
    /// @param end _schoolingPolicy.schoolingEnd will be set to it
    function setSchoolingEnd(uint256 end) external onlyOwner {
        _setSchoolingEnd(uint40(end));
    }

    /// @dev this function change breaktime without increasing the schoolingId
    /// @dev use this function to fix the value set wrong
    /// @param breaktime _schoolingPolicy.breaktime will be set to it
    function setSchoolingBreaktime(uint256 breaktime) external onlyOwner {
        _setSchoolingBreaktime(uint40(breaktime));
    }

    /// @dev add new checkpoint & uri to schoolingURI
    /// @param checkpoint schoolingTotal required to reach this checkpoint
    /// @param uri to be returned when schoolingTotal is gte to checkpoint
    function addCheckpoint(uint256 checkpoint, string memory uri)
        external
        onlyOwner
    {
        _addCheckpoint(checkpoint, uri);
    }

    /// @dev replace existing checkpoint & uri in schoolingURI
    /// @param checkpoint schoolingTotal required to reach this checkpoint
    /// @param uri to be returned when schoolingTotal is gte to checkpoint
    /// @param index means nth element, start from 0
    function replaceCheckpoint(
        uint256 checkpoint,
        string memory uri,
        uint256 index
    ) external onlyOwner {
        _replaceCheckpoint(checkpoint, uri, index);
    }

    /// @dev replace existing checkpoint & uri in schoolingURI
    /// @param index means nth element, start from 0
    function removeCheckpoint(uint256 index) external onlyOwner {
        _removeCheckpoint(index);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /// @dev withdraw balance of smart contract patially
    /// @param amount is the amout to withdraw
    function patialWithdraw(uint256 amount) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance >= amount, "Not enough balance");
        payable(msg.sender).transfer(balance);
    }

    /// @dev withdraw all balance of smart contract
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setRoylatyInfo(uint256 _royaltyRatio) external onlyOwner nonReentrant {
      royaltyRatio = _royaltyRatio;
    }
 
    /// @dev see IERC-2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      _tokenId; // silence solc warning
      receiver = owner();
      royaltyAmount = (_salePrice / 100) * royaltyRatio;
      return (receiver, royaltyAmount);
    } 
}
