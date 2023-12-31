// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 *          ⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⠟⠛⢦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 *          ⠀⠀⠀⠀⠀⠀⠀⣰⠟⠋⠁⠀⢸⡇⠀⠀⠀⢀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 *          ⠀⠀⠀⠀⠀⠀⠀⠹⣦⣀⣀⣀⣀⡇⠀⠀⢰⠋⠉⢻⠶⢦⡄⠀⠀⠀⠀⠀⠀⠀
 *          ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠁⠀⠀⢸⡆⠀⠀⠀⢀⡿⠀⠀⠀⠀⠀⠀⠀
 *          ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢷⣀⣤⠶⠋⠀⠀⠀⠀⠀⠀⠀⠀
 *          ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣆⡀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 *          ⠀⠀⠀⠀⠀⣠⠞⠛⠉⠀⠈⠙⢧⡀⠀⠀⠀⠀⢀⣠⠴⠶⠶⠶⣤⡀⠀⠀⠀⠀
 *          ⠀⠀⠀⠀⢀⡏⣀⣠⡴⠶⣆⠀⣈⣧⠀⠀⠀⢰⠏⠁⠀⠀⠀⠀⠀⢻⡄⠀⠀⠀
 *          ⠀⠀⠀⠀⣟⠛⠁⠀⠀⠀⠈⠛⠙⠛⡇⠀⠀⡟⢀⣠⣤⣤⠾⢷⣄⠀⣧⠀⠀⠀
 *          ⠀⠀⠀⠀⠙⢦⡀⠀⠀⠀⠀⠀⢀⡼⠃⠀⠀⡇⢸⡇⠀⠀⠀⠀⢸⡇⢻⠀⠀⠀
 *          ⠀⠀⠀⠀⠀⠈⠻⣄⡀⠀⣀⣴⠟⠀⠀⠀⠀⣧⣸⣇⠀⠀⠀⠀⣼⢃⣸⡇⠀⠀
 *          ⠀⠀⠀⠀⠀⠀⠀⢸⡏⠉⠉⣿⡀⠀⠀⠀⠀⠉⠉⠙⡷⠦⠴⣾⠉⠉⠉⠁⠀⠀
 *          ⠀⠀⠀⠀⠀⣀⡴⠞⠛⠒⠚⠋⠉⠛⠶⣤⣀⠀⣠⡴⠳⠶⠶⠛⠶⣄⡀⠀⠀⠀
 *          ⠀⠀⣀⡴⠞⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣽⠟⠁⠀⠀⠀⠀⠀⠀⠈⠙⢶⡄⠀
 *          ⠀⣰⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢷⠀
 *          ⢀⡟⠀⠀⢰⡆⠀⠀⠀⠀⠀⠀⠀⠀⢠⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡆
 *          ⢸⠇⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⡾⠀⠀⢰⠀⠀⠀⠀⠀⠀⠀⠀⣶⠀⠀⣧
 *          ⣼⣀⣀⣀⣸⣇⣀⣀⣀⣀⣀⣀⣀⣸⣃⣀⣀⣸⣀⣀⣀⣀⣀⣀⣀⣀⣿⣀⣀⣸
 * @title KryptoSvatbaVT
 * @dev This is a wedding gift contract. The prupose is to
 *  approximately record the wedding date & to give something
 *  funny to the newlyweds
 */

contract KryptoSvatbaVT {
    // Keep as constants as they should be!
    address constant BRIDE = 0xB71430d596313e774940c2969725B4e870Ae9059;
    address constant GROOM = 0x6B977d49fcfa6e934d03405bc86Ea1Bc5042F2E4;

    // The wedding gift
    struct Gift {
        bool sheWants;
        bool heWants;
    }

    // To use forever after
    struct Family {
        address wife;
        address husband;
        address home;
    }

    // Initiate structs
    Gift gift;
    Family family;

    // Let everyone know what they've promised
    event ShePromised(string what);
    event HePromised(string what);

    // Gift unwrapping
    event GivenGift(string greeting, string from, uint256 amount);
    event GiftUnwrapped();

    /**
     *  @dev function for sending gifts
     */
    function sendGift(string calldata _greeting, string calldata _from) external payable {
        emit GivenGift(_greeting, _from, msg.value);
    }

    /**
     *  @dev super important function for calling out a promise
     *  @param _what string is the made promise
     */
    function iPromise(string calldata _what) external payable {
        if (msg.sender == BRIDE) {
            family.wife = BRIDE;
            emit ShePromised(_what);
        } else if (msg.sender == GROOM) {
            family.husband = GROOM;
            emit HePromised(_what);
        } else {
            revert();
        }
    }

    /**
     *  @dev function to withdraw the wedding gift
     *  @param _home address is the account to which the entire balance of the gift should be send to
     */
    function brightFuture(address _home) external {
        if (_home == address(0)) revert();

        if (msg.sender == family.wife) {
            gift.sheWants = true;
            handleHome(_home);
        }

        if (msg.sender == family.husband) {
            gift.heWants = true;
            handleHome(_home);
        }

        if (gift.sheWants && gift.heWants) {
            payable(family.home).transfer(address(this).balance);
            emit GiftUnwrapped();
        }
    }

    /**
     *  @dev internal function for home address handling
     *  @param _home address to be set or checked
     */
    function handleHome(address _home) internal {
        if (family.home == address(0)) {
            family.home = _home;
        } else if (family.home != _home) {
            revert();
        }
    }
}