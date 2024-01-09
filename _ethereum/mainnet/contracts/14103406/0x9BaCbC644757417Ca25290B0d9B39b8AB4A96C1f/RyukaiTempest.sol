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
    
    constructor(string memory name, string memory symbol, uint256 supply, uint256 genCount, string memory _initNotRevealedUri) RyukaiTempestERC721(name, symbol, supply, genCount, _initNotRevealedUri) {}


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