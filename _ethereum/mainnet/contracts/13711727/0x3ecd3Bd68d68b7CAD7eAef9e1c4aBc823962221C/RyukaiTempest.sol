// SPDX-License-Identifier: MIT
/**

Ryukai - Tempest Island

MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNNNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmhsymMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMmdhhhNNNNMMMMMMMMMMMMMNmhhyoNNMMMMNNmhhhhhhhhhdNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMNdhsssssssmNNNNNNNNNNNNNmhhyyNNNNNNdyyhddhhs++oohmNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNNhhyssssoooooooooooooosyyyyhdmsdmhyyomdoydmmmmyhhmNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMNdhhyyyyyyyyyyyyyyyyyyysssyyydddhhyymdyydNdhhNdhhmNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMNdhhhhyyyyyyyyyyyyyyyydddddddhyhhyyhddydNhysshhhhdNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMNNmhhyyyyysssyyyyyymdhhooooyddddhhyydmmhhysdmyyyymNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMNdhhhhyyyysyyysyydddyyyssooosdddhdhyhhyyddhyyyyhdMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMNmhhhhhyyyyyssssyhddhyyyyyyyyyhhyyyyyyyyhyyyyyyhmNMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMNmmmmmmdmdhhhhyyyyyysssyyhmmmdhhhhhhyyyyyyyyyyyyyyyyyyyhNMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMmhoooooooyhdddddhhyyyyyyyyyhhhhdddddddddddddyyyyyyyyyyydNMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNmyssyyyyyyyyyhhhdddddhhhyyyyyhhhhhhhhhhdddddddhhhhhyyyhhhdNMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMNhosyhhhhhhhhhhhhhhhhhhhhhhyyyyhhhhhhhhhhhhhhhhhyyyyyyyyyyydmMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMNdydmNNdhhddddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhyyyyyyyyyyyyyyNMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMNmyssssyhhdddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhyyyyyyyyyyyyyhmNMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMmysssyyyyyyyhhdmhhhhhhhhhdhhhhhhhhhhhhhhhhhhyyyyyyyyyyyyyyyhhNNNMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMmhosyyyyhdddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhyyyyyyyyyyyyyyyyhmmmMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMNy+yyyhdmmyyhmdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhyyyyyyyyyyyyyyyyyyyyhNNNMMMMMMMMMMMMM
MMMMMMMMMMMMNsyhhhhdsoossyyyhhhhhhhhhdmmmmdddhhhhhhhhhhhhhhhhhhhhdmdddhhhhhhhhhyyyhhhhdNmmmmmMMMMMMM
MMMMMMMMMMMMNdmNNNm+sssyyyyyhhhhhhhhmmhhdN--:yhdhhhhhhhhhhhhhhhhNhso+shhhhhhhddhhdddhhhhsoooyNMMMMMM
MMMMMMMMMMMMMMMMMNm+syyyhhhhhhhhhhhmdhhhdN----/sdddhhhhhhhhhhhhhddddsssssshhhyhhyhhyhhhssyddmNMMMMMM
MMMMMMMMMMMMMMMMNyosyhhdmmmdhhhhhhdmhhhmy:---/::::+hhhhhhhhhhhhhhhhhyyyyyyyyhdyyyyhdyyyyyydmNMMMMMMM
MMMMMMMMMMMMMMMMNyodmNNhhhhdddhhdddhhhhms.---///:--::::::::oydhhhhhhhyyyyyyyyyyyyyyyyyyyyhNMMMMMMMMM
MMMMMMMMMMMMMMMMNddMMMNhhhhhhddddhhdhhhmy-:::+////::::::::---ohddhhhhhhhhhhyyyyyyyyyyyyhdmMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMNmhhhhhhhhhhhhhdhhhhhdyyyds++++////////:--://yddhhhhhhhhhhhhhhhhhhhhmNMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMNmhhhhhhhhhhhhhdhhhhdN:--yyyhhhsssssss++//:::::-yyyyyyyyyyyyyyyyyyyNNMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMNmhhhhhhhhhhhhhhhhhhhdho:://oooyyyyyyyhhy+++//::-----------------+yMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMNmhhhhhhhhhdhhhhhhhhhhNs--//////////++ssymmhoo+//:------------:+hmMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMNmhhhhhhhhhdhhhhhhhhhhNs--------------ohNMMMNNmyyo+++++++++++shNMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMNdhhhhhhhddhhhhhhhhhhdhy:::----------+hNMMMMMMMMmhhhhhhhhhhhNMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMNhhhdhhhhhhhhhhhhhhhhdm---:::://////+hNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMNhhhdhhhhhhhhhhhdhhhhdd+:------------/oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMNhhhdhhhhhhhhhhhdhhhhhhNo::::---------:ymMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMNdhdhhhhhhhhhhddhhhhhhhdy--::::::::::/+hmMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMNmhhhhhhhhhhhhhhhhhhhhhdd/:------------/odNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMNmhhhhhhhhhdhhhhhhhhhhhhhdhs:::----------/shNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMNmhhhhhhhhhdhhhhhhhhhhhhhhhhd+:::::::::::::/smNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMNNhhhhhhhddhhhhhhhhhhhhhhhhddy/:------------+ydMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMNhhhhhdhhhhhhhhhhhhhhhhhhhhhhdyo::----------/oydNMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMNhhhhhdhhhhhhhhhhhhhhhhhdhhhhhhhh::::::::::://+ymMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMNdhhhhdhhhhhhhhhhhhhhhhhdhhhhhhhhmo-----------++sNMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMNdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhs:::--------/oymMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMNdhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhdm---:::://///++hNMMMMMMMMMMMMMMMMMMMMMMM

Twitter: https://twitter.com/RyukaiTempest
Discord: discord.gg/RyukaiTempest
Website: RyukaiTempest.com

Contract forked from KaijuKingz

 */                                                                         

pragma solidity ^0.8.0;

import "./RyukaiTempestERC721.sol";

interface IFCore {
    function burn(address _from, uint256 _amount) external;
    function updateReward(address _from, address _to) external;
} 

contract RyukaiTempest is RyukaiTempestERC721 {
    

    modifier ryukaiOwner(uint256 ryukaiId) {
        require(ownerOf(ryukaiId) == msg.sender, "Cannot interact with a RyukaiTempest you do not own");
        _;
    }

    IFCore public FCore;
    
    uint256 constant public FUSION_PRICE = 555 ether;


    /**
     * @dev Keeps track of the state of Baby Ryukai
     * 0 - Unminted
     * 1 - Fusion
     */
    mapping(uint256 => uint256) public babyRyukai;

    event ryukaiFusion(uint256 ryukaiId, uint256 parent1, uint256 parent2);
    

    constructor(string memory name, string memory symbol, uint256 supply, uint256 genCount, string memory _initNotRevealedUri) RyukaiTempestERC721(name, symbol, supply, genCount, _initNotRevealedUri) {}

    function fusion(uint256 parent1, uint256 parent2) external ryukaiOwner(parent1) ryukaiOwner(parent2) {
        uint256 supply = totalSupply();
        require(supply < maxSupply,                               "Cannot fuse any more baby Ryukais");
        require(parent1 < maxGenCount && parent2 < maxGenCount,   "Cannot fuse with baby Ryukais");
        require(parent1 != parent2,                               "Must select two unique parents");

        FCore.burn(msg.sender, FUSION_PRICE);
        uint256 ryukaiId = maxGenCount + babyCount;
        babyRyukai[ryukaiId] = 1;
        babyCount++;
        _safeMint(msg.sender, ryukaiId);
        emit ryukaiFusion(ryukaiId, parent1, parent2);
    }

    function setFusionCore(address FCoreAddress) external onlyOwner {
        FCore = IFCore(FCoreAddress);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (tokenId < maxGenCount) {
            FCore.updateReward(from, to);
            balanceGenesis[from]--;
            balanceGenesis[to]++;
        }
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        if (tokenId < maxGenCount) {
            FCore.updateReward(from, to);
            balanceGenesis[from]--;
            balanceGenesis[to]++;
        }
        ERC721.safeTransferFrom(from, to, tokenId, data);
    }
}