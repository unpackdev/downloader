// SPDX-License-Identifier: Unlicense
/*
    8|8888888888888888888|888|88888
    8.|.......|............|......8
    8.....................|.......8
    8....|.......RRRRR.|..........8
    8..........RREEEEER|......|.|.8
    8........RREEFFFFFEER|........8
    8....|..R.EFFLL|LLFFE.R.......8
    8...|..R.EFLLEEEEELLFE.R.....|8
    8..|..R.EF|.ECCCCCE.LFE.R.....8
    8....R.EFL.EC.TTT.CE.LFE.R....8
    8....REFL.ECTTII|TTCE.LFER....8
    8...REFL.ECT.IOOOI.|CE.LFER...8
    8|..REFLECT.IONNNO|.TCELFER...8
    8..REFLEC.TION.|.NOIT.C|LFER..8
    8..RE||E|TIO|.....NOITCEL||R..8
    8..R|FLECTION.....NOITCELF|R..8
    8..REF|ECTI|N.....NOI|CELFER..8
    8..REFLEC.TION|..NOIT.CELFER..8
    |...REFLECT.IONNNOI.TCELFE|...8
    8...R|FL.ECT.IOOOI.TCE.LFER...8
    8....R|FL.ECTTIIITTCE.LFER....8
    8.|..R||F|.EC.TTT.CE.LFE.R....8
    8.....R.EFL.ECCCCCE.LFE.|.....8
    8.....|R.EFLLEEEEELLFE.R|.....8
    8.......R.EF|LLLLLFFE.R.......8
    8........|REEF|FFFEERR........8
    8..........RREEEEERR..........8
    8............RRRRR............8
    8...................|.........8
    8....|.....................|..8
    8888888888888888888888888888888

    (8) This is the community’s offering to the daemon, an homage to the spirit of Corruption(s*) and a tribute to dhof. 
    If anyone else wants to make an offering to the daemon,  please send art to reflection-s.eth
*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface ICorruptions {
    function insight(uint256 tokenID) external view returns (uint256);
}

interface ICorruptionsDataMapper {
    function valueFor(uint256 mapIndex, uint256 key)
        external
        view
        returns (uint256);
}

interface IReflectionsMetadata {
    function tokenURI(uint256 tokenId, uint256 amount)
        external
        view
        returns (string memory);
}

contract Reflections is ERC721, ReentrancyGuard, Ownable {
    mapping(uint256 => bool) public claimed;
    uint256 private balance;

    address public metadataAddress = 0x7572f8cC39266AEa2A29cAd3536C8f8904a599f8;
    address public corruptionsAddress =
        0x5BDf397bB2912859Dbd8011F320a222f79A28d2E;
    address public corruptionsDataMapperAddress =
        0x7A96d95a787524a27a4df36b64a96910a2fDCF5B;

    constructor() ERC721("Reflections", "REFLECT") {
        _mint(0x4fFFFF3eD1E82057dffEe66b4aa4057466E24a38, 1);
        claimed[1] = true;
    }

    function setMetadataAddress(address addr) public onlyOwner {
        metadataAddress = addr;
    }

    function insight(uint256 tokenID) public view returns (uint256) {
        return ICorruptions(corruptionsAddress).insight(tokenID);
    }

    function tokenURI(uint256 tokenID)
        public
        view
        override
        returns (string memory)
    {
        require(
            metadataAddress != address(0),
            "Reflections: no metadata address"
        );
        require(claimed[tokenID], "Reflections: token doesn't exist");
        return
            IReflectionsMetadata(metadataAddress).tokenURI(
                tokenID,
                insight(tokenID)
            );
    }

    function mint(uint256 tokenID) public payable nonReentrant {
        require(msg.value == 0.064 ether, "Reflections: 0.064 ETH to mint");
        require(
            ERC721(corruptionsAddress).ownerOf(tokenID) == msg.sender,
            "Reflections: not owner"
        );
        require(
            ICorruptionsDataMapper(corruptionsDataMapperAddress).valueFor(
                0,
                tokenID
            ) != 0,
            "Reflections: not deviated"
        );
        require(!claimed[tokenID], "Reflections: already claimed");
        _mint(_msgSender(), tokenID);
        balance += 0.064 ether;
        claimed[tokenID] = true;
    }

    function withdrawAvailableBalance() public nonReentrant onlyOwner {
        uint256 b = balance;
        balance = 0;
        payable(msg.sender).transfer(b);
    }
}
