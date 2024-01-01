// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./MinteebleGadgetsCollection.sol";
import "./DefaultOperatorFilterer.sol";

contract SkullNBananasGadgets is
    MinteebleGadgetsCollection,
    DefaultOperatorFilterer
{
    address public withdrawAccount;

    constructor()
        MinteebleGadgetsCollection("SkullNBananasGadgets", "SNBG", "")
    {
        _grantRole(MINTER_ROLE, msg.sender);
        setPaused(false);
        setFreeItemsBuyable(false);
        setWithdrawAccount(msg.sender);

        addGadgetGroup();
        for (uint256 i = 0; i < 6; i++) {
            idsInfo.push(IdInfo(gadgetVariations[0], 0, 0));
            gadgetVariations[0]++;
        }

        addGadgetGroup();
        for (uint256 i = 0; i < 6; i++) {
            idsInfo.push(IdInfo(1 * 256 + gadgetVariations[1], 0, 0));
            gadgetVariations[1]++;
        }

        addGadgetGroup();
        for (uint256 i = 0; i < 4; i++) {
            idsInfo.push(IdInfo(2 * 256 + gadgetVariations[2], 0, 0));
            gadgetVariations[2]++;
        }

        addGadgetGroup();
        for (uint256 i = 0; i < 1; i++) {
            idsInfo.push(IdInfo(3 * 256 + gadgetVariations[3], 0, 0));
            gadgetVariations[3]++;
        }

        addGadgetGroup();
        for (uint256 i = 0; i < 128; i++) {
            idsInfo.push(IdInfo(4 * 256 + gadgetVariations[4], 0, 0));
            gadgetVariations[4]++;
        }

        uint256[] memory prices = new uint256[](9);
        prices[0] = 60000000000000000; // $100
        prices[1] = 12000000000000000; // $20
        prices[2] = 9000000000000000; // $15
        prices[3] = 7200000000000000; // $12
        prices[4] = 6000000000000000; // $10
        prices[5] = 6000000000000000; // $10
        prices[6] = 6000000000000000; // $10
        prices[7] = 3000000000000000; // $5
        prices[8] = 3000000000000000; // $5

        idsInfo[0].price = prices[1];
        idsInfo[1].price = prices[0];
        idsInfo[2].price = prices[2];
        idsInfo[3].price = prices[2];
        idsInfo[4].price = prices[3];
        idsInfo[5].price = prices[1];
        idsInfo[6].price = prices[0];
        idsInfo[7].price = prices[0];
        idsInfo[8].price = prices[4];
        idsInfo[9].price = prices[2];
        idsInfo[10].price = prices[3];
        idsInfo[11].price = prices[1];
        idsInfo[12].price = prices[0];
        idsInfo[13].price = prices[2];
        idsInfo[14].price = prices[3];
        idsInfo[15].price = prices[1];
        idsInfo[16].price = prices[0];
        idsInfo[17].price = prices[7];
        idsInfo[18].price = prices[4];
        idsInfo[19].price = prices[2];
        idsInfo[20].price = prices[5];
        idsInfo[21].price = prices[5];
        idsInfo[22].price = prices[5];
        idsInfo[23].price = prices[5];
        idsInfo[24].price = prices[6];
        idsInfo[25].price = prices[7];
        idsInfo[26].price = prices[4];
        idsInfo[27].price = prices[3];
        idsInfo[28].price = prices[5];
        idsInfo[29].price = prices[5];
        idsInfo[30].price = prices[5];
        idsInfo[31].price = prices[5];
        idsInfo[32].price = prices[6];
        idsInfo[33].price = prices[3];
        idsInfo[34].price = prices[3];
        idsInfo[35].price = prices[0];
        idsInfo[36].price = prices[0];
        idsInfo[37].price = prices[0];
        idsInfo[38].price = prices[4];
        idsInfo[39].price = prices[2];
        idsInfo[40].price = prices[4];
        idsInfo[41].price = 0; // Airdrop gadgets
        idsInfo[42].price = prices[4];
        idsInfo[43].price = prices[2];
        idsInfo[44].price = prices[6];
        idsInfo[45].price = prices[5];
        idsInfo[46].price = prices[4];
        idsInfo[47].price = prices[2];
        idsInfo[48].price = prices[2];
        idsInfo[49].price = prices[1];
        idsInfo[50].price = prices[2];
        idsInfo[51].price = prices[3];
        idsInfo[52].price = prices[5];
        idsInfo[53].price = prices[5];
        idsInfo[54].price = prices[5];
        idsInfo[55].price = prices[5];
        idsInfo[56].price = prices[5];
        idsInfo[57].price = prices[3];
        idsInfo[58].price = prices[2];
        idsInfo[59].price = prices[3];
        idsInfo[60].price = prices[6];
        idsInfo[61].price = prices[3];
        idsInfo[62].price = prices[2];
        idsInfo[63].price = prices[4];
        idsInfo[64].price = prices[5];
        idsInfo[65].price = prices[4];
        idsInfo[66].price = prices[3];
        idsInfo[67].price = prices[3];
        idsInfo[68].price = prices[4];
        idsInfo[69].price = prices[6];
        idsInfo[70].price = prices[3];
        idsInfo[71].price = prices[8];
        idsInfo[72].price = prices[2];
        idsInfo[73].price = prices[4];
        idsInfo[74].price = prices[4];
        idsInfo[75].price = prices[3];
        idsInfo[76].price = prices[3];
        idsInfo[77].price = prices[3];
        idsInfo[78].price = prices[4];
        idsInfo[79].price = prices[4];
        idsInfo[80].price = prices[4];
        idsInfo[81].price = prices[4];
        idsInfo[82].price = prices[4];
        idsInfo[83].price = prices[4];
        idsInfo[84].price = prices[4];
        idsInfo[85].price = prices[4];
        idsInfo[86].price = prices[4];
        idsInfo[87].price = prices[3];
        idsInfo[88].price = prices[3];
        idsInfo[89].price = prices[2];
        idsInfo[90].price = prices[1];
        idsInfo[91].price = prices[2];
        idsInfo[92].price = prices[1];
        idsInfo[93].price = prices[3];
        idsInfo[94].price = prices[0];
        idsInfo[95].price = prices[2];
        idsInfo[96].price = prices[1];
        idsInfo[97].price = prices[1];
        idsInfo[98].price = prices[2];
        idsInfo[99].price = prices[1];
        idsInfo[100].price = prices[2];
        idsInfo[101].price = prices[2];
        idsInfo[102].price = prices[3];
        idsInfo[103].price = prices[3];
        idsInfo[104].price = prices[3];
        idsInfo[105].price = prices[3];
        idsInfo[106].price = prices[2];
        idsInfo[107].price = prices[2];
        idsInfo[108].price = prices[1];
        idsInfo[109].price = prices[1];
        idsInfo[110].price = prices[2];
        idsInfo[111].price = prices[2];
        idsInfo[112].price = prices[0];
        idsInfo[113].price = prices[1];
        idsInfo[114].price = prices[2];
        idsInfo[115].price = prices[3];
        idsInfo[116].price = prices[5];
        idsInfo[117].price = prices[1];
        idsInfo[118].price = prices[3];
        idsInfo[119].price = prices[3];
        idsInfo[120].price = prices[8];
        idsInfo[121].price = prices[2];
        idsInfo[122].price = prices[2];
        idsInfo[123].price = prices[2];
        idsInfo[124].price = prices[1];
        idsInfo[125].price = prices[1];
        idsInfo[126].price = prices[3];
        idsInfo[127].price = prices[4];
        idsInfo[128].price = prices[4];
        idsInfo[129].price = prices[2];
        idsInfo[130].price = prices[2];
        idsInfo[131].price = prices[2];
        idsInfo[132].price = prices[2];
        idsInfo[133].price = prices[1];
        idsInfo[134].price = prices[0];
        idsInfo[135].price = prices[2];
        idsInfo[136].price = prices[1];
        idsInfo[137].price = prices[3];
        idsInfo[138].price = prices[2];
        idsInfo[139].price = prices[4];
        idsInfo[140].price = prices[6];
        idsInfo[141].price = prices[3];
        idsInfo[142].price = prices[3];
        idsInfo[143].price = prices[5];
        idsInfo[144].price = prices[3];
    }

    function setWithdrawAccount(
        address _withdrawAccount
    ) public requireAdmin(msg.sender) {
        withdrawAccount = _withdrawAccount;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function withdrawBalance()
        public
        override
        requireAdmin(msg.sender)
        nonReentrant
    {
        uint256 totBalance = address(this).balance;

        (bool hs1, ) = payable(withdrawAccount).call{value: (totBalance)}("");
        require(hs1);
    }
}
