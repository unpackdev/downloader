// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC721Upgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

/*
 * ################################################################################################################
 * ################################################################################################################
 * ###                             #####        #####                                                           ###
 * ###    ######################   #####        #####    #####   ##################   ######################    ###
 * ###    ######################                #####    #####   ##################   ######################    ###
 * ###    ##############################        ##############   ##################   ######################    ###
 * ###    #####            #############        ##############                #####   #####            #####    ###
 * ###    #####   LLLLL    #############    ##################       UUUUU    #####   #####    UUUUU   #####    ###
 * ###    #####   LLLLL                     #########    #####       UUUUU    #####   #####    UUUUU   #####    ###
 * ###    #####   LLLLL    #############    #########    #########   UUUUU    #############    UUUUU   #####    ###
 * ###    #####   LLLLL    #############                 #########   UUUUU    #############    UUUUU            ###
 * ###    #####   LLLLL    #################    #####    #########   UUUUU    #############    UUUUU   ############
 * ###    #####   LLLLL    #####    ########    #####                UUUUU            #####    UUUUU   ############
 * ###    #####   LLLLL    #####    ########    #####    #####       UUUUU    #####   #####    UUUUU   ############
 * ###    #####   LLLLL    #####        ####             #####       UUUUU    #####   #####    UUUUU   #####    ###
 * ###    #####   LLLLL    #########    ##########################   UUUUU    #############    UUUUU   #####    ###
 * ###    #####   LLLLL    #########    ##########################   UUUUU    #############    UUUUU   #####    ###
 * ###    #####   LLLLL    #########    ##########################   UUUUU    #############    UUUUU   #####    ###
 * ###            LLLLL                                      #####   UUUUU                     UUUUU            ###
 * ###    #####   LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL   ##############   UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU   #####    ###
 * ###    #####   LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL   ##############   UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU   #####    ###
 * ###    #####   LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL   ##############   UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU   #####    ###
 * ###    #####                                     #####                                              #####    ###
 * ###    #################    #############    #############    #############    ##############   #########    ###
 * ###    #################    #############    #############    #############    ##############   #########    ###
 * ###    #################    #############    #############    #############    ##############   #########    ###
 * ###                         #####    ####                     #####    ####    #####    #####   #####        ###
 * ###        ######################    #################    #########    #############    #####   #####        ###
 * ###        ######################    #################    #########    #############    #####   #####        ###
 * ###        ######################    ##############################    #############    #####   #########    ###
 * ###                                              ##############                         #####   #########    ###
 * ############   CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC   ##############        ####    IIIII    #####   #########    ###
 * ############   CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC   #####                 ####    IIIII    ####        #####    ###
 * ############   CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC   #####        #####    ####    IIIII    #################    ###
 * ###    #####   CCCCC                             #####        #####    ####             #################    ###
 * ###    #####   CCCCC    ##############################    #########    ####    IIIII    #################    ###
 * ###    #####   CCCCC    ##############################    #########    ####    IIIII                         ###
 * ###    #####   CCCCC    ##############################    #########    ####    IIIII    #####   #########    ###
 * ###    #####   CCCCC            #####                         #####    ####    IIIII    #####   #########    ###
 * ###    #####   CCCCC    #####   #####    ##########################    ####    IIIII    #####   #########    ###
 * ###    #####   CCCCC    #####   #####    ##########################    ####    IIIII    #####   #####        ###
 * ###    #####   CCCCC    #####   #####    ##########################    ####    IIIII    #####   #####        ###
 * ###    #####   CCCCC                             #####        #####    ####    IIIII    #####   #####        ###
 * ###    #####   CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC   #####        #####    ####    IIIII    #####   #########    ###
 * ###    #####   CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC   #####        #####            IIIII            #########    ###
 * ###    #####   CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC   #####    #################    IIIII    #####   #########    ###
 * ###    #####                                     #####    #################             #####       #####    ###
 * ###    #########    #################    #############    ###############################################    ###
 * ###    #########    #################    #############    #####        ##################################    ###
 * ###    #########    #################    #############    #####        ##################################    ###
 * ###                                                       #####                                              ###
 * ################################################################################################################
 * ###########################################SAM#SPRATT#SKULLS#OF#LUCI############################################
 */

contract LuciClaim is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    address private luciHolder;

    mapping(address => uint256[]) private claimerToTokenIds;
    IERC721Upgradeable public luciContractAddress;
    uint256 public totalClaimed;
    uint256 public totalLucis;

    function initialize(
        address[] memory _claimers,
        uint256[][] memory _tokenIdsPerClaimer,
        address _contractAddress,
        address _luciHolder
    ) public initializer {
        require(_claimers.length == _tokenIdsPerClaimer.length);

        __Ownable_init();
        __ReentrancyGuard_init();

        totalLucis = 0;

        for (uint16 i = 0; i < _claimers.length; i++) {
            claimerToTokenIds[_claimers[i]] = _tokenIdsPerClaimer[i];
            totalLucis += _tokenIdsPerClaimer[i].length;
        }

        totalClaimed = 0;

        luciContractAddress = IERC721Upgradeable(_contractAddress);

        luciHolder = _luciHolder == address(0) ? address(this) : _luciHolder;
    }

    function claimLucis() external nonReentrant {
        uint256[] memory tokenIds = claimerToTokenIds[msg.sender];

        require(tokenIds.length > 0, "no tokens to claim");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(luciContractAddress.ownerOf(tokenId) == luciHolder);
            luciContractAddress.safeTransferFrom(
                luciHolder,
                msg.sender,
                tokenId
            );
        }

        totalClaimed += tokenIds.length;

        delete claimerToTokenIds[msg.sender];
    }

    function withdraw(uint256[] calldata _tokenIds, address _receiver)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (luciContractAddress.ownerOf(_tokenIds[i]) == luciHolder) {
                luciContractAddress.safeTransferFrom(
                    luciHolder,
                    _receiver,
                    _tokenIds[i]
                );
            }
        }
    }

    function getTokenIdsForClaimer(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return claimerToTokenIds[_user];
    }
}
