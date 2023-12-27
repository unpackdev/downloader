// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//                              .-----.
//                             /7  .  (
//                            /   .-.  \
//                           /   /   \  \
//                          / `  )   (   )
//                         / `   )   ).  \
//                       .'  _.   \_/  . |
//      .--.           .' _.' )`.        |
//     (    `---...._.'   `---.'_)    ..  \
//      \            `----....___    `. \  |
//       `.           _ ----- _   `._  )/  |
//         `.       /"  \   /"  \`.  `._   |
//           `.    ((O)` ) ((O)` ) `.   `._\
//             `-- '`---'   `---' )  `.    `-.
//                /                  ` \      `-.
//              .'                      `.       `.
//             /                     `  ` `.       `-.
//      .--.   \ ===._____.======. `    `   `. .___.--`     .''''.
//     ' .` `-. `.                )`. `   ` ` \          .' . '  8)
//    (8  .  ` `-.`.               ( .  ` `  .`\      .'  '    ' /
//     \  `. `    `-.               ) ` .   ` ` \  .'   ' .  '  /
//      \ ` `.  ` . \`.    .--.     |  ` ) `   .``/   '  // .  /
//       `.  ``. .   \ \   .-- `.  (  ` /_   ` . / ' .  '/   .'
//         `. ` \  `  \ \  '-.   `-'  .'  `-.  `   .  .'/  .'
//           \ `.`.  ` \ \    ) /`._.`       `.  ` .  .'  /
//            |  `.`. . \ \  (.'               `.   .'  .'
//         __/  .. \ \ ` ) \                     \.' .. \__
//  .-._.-'     '"  ) .-'   `.                   (  '"     `-._.--.
// (_________.-====' / .' /\_)`--..__________..-- `====-. _________)
// frog.capital

contract FrogCapitalPaymentProcessor {

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function FrogCapSub(address[] memory _recipients, uint[] memory _values) public payable {
        require(_recipients.length == _values.length, "Array lengths must match");

        uint total = 0;
        for (uint i = 0; i < _values.length; i++) {
            total += _values[i];
        }

        require(msg.value >= total, "Sent ETH value is less than the total value to transfer");

        for (uint i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            uint value = _values[i];
            (bool success, ) = recipient.call{value:value}("");
            require(success, "transfer failed");
        }

// Send back the remaining ETH to the sender (if any)
        uint remaining = address(this).balance;
        if (remaining > 0) {
            payable(msg.sender).transfer(remaining);
        }
    }

// Allow owner to withdraw any ETH left in the contract
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(owner).transfer(balance);
    }
}