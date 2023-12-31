
/*
Mobit - Pioneering the Future of Digital Wallets
AN UPCOMING DIGITAL WALLET USING MOBILE TECHNOLOGY FOR SECURE, 
EFFICIENT, AND COST-EFFECTIVE MANAGEMENT OF YOUR CRYPTOCURRENCIES.


FEATURES
1. Innovative Security
Using cutting-edge technology, 
we aim to implement a dual-verification process involving physical and digital authentication. 
This involves creating a unique link between your mobile device and computer, 
authenticated by your mobile device's MAC address. This link acts as a secure gate for your transactions, 
making Mobit as secure as a cold wallet.

2. Low Costs
Our vision encompasses a decentralized economy with minimal costs for the users. 
Once operational, you will only need to pay a service fee of $3 equivalent in MOBIT tokens per month 
for unlimited access to our services. This model ensures that the benefits of blockchain technology are accessible to all, 
irrespective of transaction volumes.

3. Tax-Free Transactions
We understand the burden taxation can bring. Our model is designed to lift this burden from your shoulders. 
Once we collect a total of 100 ETH in taxes, your subsequent transactions will be tax-free, 
thereby increasing your profit margins.

4. Intuitive Interface
Our user-friendly platform will be designed to cater to both beginners and seasoned crypto-enthusiasts. 
The navigation will be seamless, making your cryptocurrency management effortless.

5. Universal Compatibility
Our system will be compatible with all major cryptocurrencies,
giving you the freedom to manage a diverse portfolio in one place.

6. Real-time Tracking
Stay updated with real-time tracking of your transactions and portfolio. 
With our system, you'll be informed and in control at all times.

web https://mobit.solutions/
tg  https://t.me/MobitOfficialPortal
twt https://twitter.com/Mobit_ERC20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract MOBIT is ERC20 { 
    constructor() ERC20("Mobit", "MOBIT") { 
        _mint(msg.sender, 100_000_000 * 10**18);
    }
}