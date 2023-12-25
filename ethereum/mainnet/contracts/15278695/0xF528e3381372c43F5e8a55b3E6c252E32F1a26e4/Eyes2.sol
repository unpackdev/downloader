// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

library Eyes2 {
    function opaline(string memory _fill) external pure returns (string memory) {
        return
            string.concat(
                '<circle cx="58" cy="79" r="22" fill="',
                _fill,
                '"/>',
                '<circle cx="142" cy="79" r="22" fill="',
                _fill,
                '"/>',
                '<path d="M45.6829 86.5051C45.615 86.0823 45.8239 85.6632 46.2023 85.4628L48.3117 84.3458C48.6981 84.1411 49.1727 84.2113 49.4834 84.5191L51.1522 86.1722C51.4589 86.476 51.536 86.9422 51.3435 87.3286L50.2685 89.486C50.076 89.8724 49.6573 90.0916 49.2301 90.0297L46.9054 89.6929C46.4726 89.6302 46.1308 89.2936 46.0614 88.8618L45.6829 86.5051Z" fill="white" fill-opacity="0.9"/>',
                '<path d="M49.0832 72.1223C49.0972 72.4245 48.962 72.5987 48.6777 72.6448C48.5583 72.6642 48.4466 72.6413 48.3427 72.5762C48.2387 72.511 48.1685 72.4199 48.132 72.3028C47.975 71.766 47.8354 71.3552 47.7134 71.0705C47.5961 70.7791 47.4453 70.5692 47.2611 70.441C47.0826 70.3118 46.8215 70.2311 46.4779 70.199C46.1389 70.1602 45.6664 70.1256 45.0604 70.095C44.7782 70.0822 44.6158 69.9445 44.5733 69.682C44.5538 69.5621 44.5765 69.4501 44.6413 69.3459C44.7061 69.2417 44.7968 69.1713 44.9135 69.1348C45.4814 68.9666 45.9215 68.8191 46.2336 68.6924C46.5456 68.5656 46.7683 68.4094 46.9016 68.2238C47.0349 68.0382 47.1098 67.7801 47.1262 67.4494C47.1483 67.1179 47.1477 66.6641 47.1243 66.088C47.1169 65.7905 47.2525 65.6192 47.5312 65.574C47.8155 65.5279 47.9988 65.6504 48.081 65.9417C48.2371 66.4728 48.3738 66.884 48.4911 67.1754C48.6075 67.4611 48.7573 67.6652 48.9406 67.7878C49.1238 67.9104 49.3878 67.9906 49.7324 68.0284C50.0761 68.0605 50.5481 68.0923 51.1485 68.1238C51.4373 68.1414 51.6025 68.2786 51.6441 68.5355C51.6885 68.8094 51.5581 68.9945 51.2527 69.0909C50.698 69.2687 50.2679 69.4234 49.9624 69.5549C49.6569 69.6864 49.4375 69.845 49.3042 70.0306C49.1709 70.2162 49.0956 70.4715 49.0783 70.7964C49.0609 71.1214 49.0626 71.5633 49.0832 72.1223Z" fill="white" fill-opacity="0.9"/>',
                '<circle cx="61.5" cy="64.5" r="2.5" fill="white" fill-opacity="0.9"/>',
                '<circle cx="54.5" cy="65.5" r="1.5" fill="white" fill-opacity="0.9"/>',
                '<circle cx="69" cy="67" r="1" fill="white" fill-opacity="0.9"/>',
                '<circle cx="73" cy="74" r="1" fill="white" fill-opacity="0.9"/>',
                '<circle cx="63" cy="93" r="1" fill="white" fill-opacity="0.9"/>',
                '<circle cx="43" cy="84" r="1" fill="white" fill-opacity="0.9"/>',
                '<circle cx="44" cy="72" r="1" fill="white" fill-opacity="0.9"/>',
                string.concat(
                    '<circle cx="51" cy="94" r="1" fill="white" fill-opacity="0.9"/>',
                    '<ellipse cx="71.2904" cy="83.7158" rx="3.60879" ry="2.40586" transform="rotate(-25.2591 71.2904 83.7158)" fill="white" fill-opacity="0.9"/>',
                    '<path d="M56.6664 88.3688C56.7484 88.5271 56.871 88.6329 57.0344 88.6863C57.199 88.7431 57.3906 88.7546 57.6091 88.7208L59.8863 88.3738L60.9745 90.3967C61.0816 90.5926 61.2062 90.7386 61.3483 90.8346C61.4918 90.9339 61.6513 90.9686 61.827 90.9387C61.9992 90.9097 62.1345 90.8289 62.2328 90.696C62.3334 90.5643 62.3962 90.3942 62.4211 90.1857L62.6945 87.964L64.9705 87.6458C65.1902 87.6153 65.367 87.5509 65.5008 87.4525C65.6345 87.3541 65.7107 87.2187 65.7294 87.0462C65.7504 86.8748 65.7103 86.7206 65.6091 86.5835C65.5079 86.4464 65.3583 86.3299 65.1605 86.2342L63.0724 85.2154L63.3893 82.9944C63.4199 82.7803 63.4041 82.5948 63.3419 82.438C63.2821 82.2823 63.1737 82.1654 63.0168 82.0873C62.8575 82.008 62.6966 81.9908 62.5339 82.0357C62.3736 82.0817 62.2173 82.1814 62.0649 82.3349L60.4834 83.9261L58.4085 82.8719C58.2153 82.7729 58.0334 82.7243 57.863 82.7261C57.6926 82.728 57.5459 82.7878 57.4229 82.9055C57.2965 83.0244 57.2338 83.168 57.2347 83.3363C57.2391 83.5035 57.2942 83.6834 57.4 83.8759L58.5176 85.884L56.9093 87.4409C56.7579 87.5865 56.66 87.7391 56.6155 87.8988C56.5711 88.0584 56.5881 88.2151 56.6664 88.3688Z" fill="white" fill-opacity="0.9"/>',
                    '<path fill-rule="evenodd" clip-rule="evenodd" d="M52.9292 80.493C53.3951 78.0879 56.1205 79.674 54.2643 81.2575C56.5734 80.4584 56.5579 83.6048 54.2589 82.796C56.1189 84.3923 53.3779 85.9525 52.9351 83.5603C52.4693 85.9654 49.7535 84.3959 51.6 82.7957C49.2838 83.6212 49.2993 80.4748 51.6055 81.2572C49.7384 79.6873 52.4864 78.1007 52.9292 80.493Z" fill="white" fill-opacity="0.9"/>',
                    '<path fill-rule="evenodd" clip-rule="evenodd" d="M57.3165 92.4697C57.5912 91.0518 59.198 91.9869 58.1036 92.9205C59.465 92.4494 59.4559 94.3044 58.1004 93.8275C59.197 94.7686 57.5811 95.6885 57.32 94.2781C57.0454 95.6961 55.4442 94.7708 56.5329 93.8274C55.1673 94.314 55.1765 92.459 56.5361 92.9203C55.4353 91.9948 57.0555 91.0593 57.3165 92.4697ZM57.2111 93.1997C57.3099 93.1426 57.4442 93.17 57.501 93.2684C57.5578 93.3668 57.5201 93.5067 57.4213 93.5637C57.3225 93.6208 57.1923 93.5778 57.1355 93.4794C57.0787 93.3811 57.1123 93.2567 57.2111 93.1997Z" fill="white" fill-opacity="0.9"/>',
                    '<path d="M57.4651 77.0869C57.683 77.417 57.6477 77.7029 57.3593 77.9448C57.2382 78.0464 57.0975 78.0954 56.9372 78.0918C56.777 78.0881 56.6372 78.0328 56.5179 77.9257C55.9826 77.428 55.5512 77.0601 55.2238 76.822C54.8972 76.5733 54.5876 76.4385 54.295 76.4176C54.0082 76.3919 53.6611 76.476 53.2538 76.6697C52.8473 76.8529 52.2936 77.1299 51.5927 77.5008C51.2673 77.6752 50.9929 77.6292 50.7696 77.3629C50.6676 77.2413 50.6182 77.1004 50.6212 76.94C50.6243 76.7797 50.6791 76.64 50.7857 76.5211C51.3109 75.9524 51.7063 75.4925 51.972 75.1415C52.2376 74.7905 52.3832 74.4662 52.4088 74.1687C52.4343 73.8711 52.3457 73.5312 52.1431 73.149C51.9461 72.762 51.642 72.2529 51.2305 71.6217C51.0232 71.2926 51.0609 71.0095 51.3436 70.7725C51.632 70.5306 51.9197 70.5457 52.2068 70.8176C52.7372 71.3095 53.1658 71.6799 53.4923 71.9286C53.814 72.1716 54.1187 72.3006 54.4064 72.3156C54.6942 72.3307 55.0442 72.2442 55.4564 72.0563C55.8637 71.8625 56.415 71.5826 57.1101 71.2165C57.4462 71.0431 57.7234 71.0867 57.9419 71.3472C58.175 71.625 58.1523 71.9201 57.8739 72.2325C57.37 72.8031 56.9905 73.2644 56.7354 73.6164C56.4804 73.9683 56.3401 74.2931 56.3146 74.5906C56.289 74.8882 56.3752 75.2252 56.573 75.6016C56.7708 75.978 57.0682 76.4731 57.4651 77.0869Z" fill="white" fill-opacity="0.9"/>',
                    '<circle cx="45" cy="78" r="2" fill="white" fill-opacity="0.9"/>',
                    '<ellipse cx="53.5" cy="90" rx="1.5" ry="1" fill="white" fill-opacity="0.9"/>',
                    '<ellipse cx="67.5" cy="90" rx="1.5" ry="2" fill="white" fill-opacity="0.9"/>',
                    '<circle cx="149" cy="75" r="6" fill="white"/>',
                    '<path d="M129.683 86.5051C129.615 86.0823 129.824 85.6632 130.202 85.4628L132.312 84.3458C132.698 84.1411 133.173 84.2113 133.483 84.5191L135.152 86.1722C135.459 86.476 135.536 86.9422 135.344 87.3286L134.269 89.486C134.076 89.8724 133.657 90.0916 133.23 90.0297L130.905 89.6929C130.473 89.6302 130.131 89.2936 130.061 88.8618L129.683 86.5051Z" fill="white" fill-opacity="0.9"/>',
                    '<path d="M133.083 72.1223C133.097 72.4245 132.962 72.5987 132.678 72.6448C132.558 72.6642 132.447 72.6413 132.343 72.5762C132.239 72.511 132.169 72.4199 132.132 72.3028C131.975 71.766 131.835 71.3552 131.713 71.0705C131.596 70.7791 131.445 70.5692 131.261 70.441C131.083 70.3118 130.822 70.2311 130.478 70.199C130.139 70.1602 129.666 70.1256 129.06 70.095C128.778 70.0822 128.616 69.9445 128.573 69.682C128.554 69.5621 128.577 69.4501 128.641 69.3459C128.706 69.2417 128.797 69.1713 128.913 69.1348C129.481 68.9666 129.921 68.8191 130.234 68.6924C130.546 68.5656 130.768 68.4094 130.902 68.2238C131.035 68.0382 131.11 67.7801 131.126 67.4494C131.148 67.1179 131.148 66.6641 131.124 66.088C131.117 65.7905 131.253 65.6192 131.531 65.574C131.815 65.5279 131.999 65.6504 132.081 65.9417C132.237 66.4728 132.374 66.884 132.491 67.1754C132.607 67.4611 132.757 67.6652 132.941 67.7878C133.124 67.9104 133.388 67.9906 133.732 68.0284C134.076 68.0605 134.548 68.0923 135.148 68.1238C135.437 68.1414 135.602 68.2786 135.644 68.5355C135.689 68.8094 135.558 68.9945 135.253 69.0909C134.698 69.2687 134.268 69.4234 133.962 69.5549C133.657 69.6864 133.438 69.845 133.304 70.0306C133.171 70.2162 133.096 70.4715 133.078 70.7964C133.061 71.1214 133.063 71.5633 133.083 72.1223Z" fill="white" fill-opacity="0.9"/>',
                    '<circle cx="145.5" cy="64.5" r="2.5" fill="white" fill-opacity="0.9"/>',
                    '<circle cx="138.5" cy="65.5" r="1.5" fill="white" fill-opacity="0.9"/>',
                    '<circle cx="153" cy="67" r="1" fill="white" fill-opacity="0.9"/>',
                    string.concat(
                        '<circle cx="157" cy="74" r="1" fill="white" fill-opacity="0.9"/>',
                        '<circle cx="147" cy="93" r="1" fill="white" fill-opacity="0.9"/>',
                        '<circle cx="127" cy="84" r="1" fill="white" fill-opacity="0.9"/>',
                        '<circle cx="128" cy="72" r="1" fill="white" fill-opacity="0.9"/>',
                        '<circle cx="135" cy="94" r="1" fill="white" fill-opacity="0.9"/>',
                        '<ellipse cx="155.29" cy="83.7158" rx="3.60879" ry="2.40586" transform="rotate(-25.2591 155.29 83.7158)" fill="white" fill-opacity="0.9"/>',
                        '<path d="M140.666 88.3688C140.748 88.5271 140.871 88.6329 141.034 88.6863C141.199 88.7431 141.391 88.7546 141.609 88.7208L143.886 88.3738L144.975 90.3967C145.082 90.5926 145.206 90.7386 145.348 90.8346C145.492 90.9339 145.651 90.9686 145.827 90.9387C145.999 90.9097 146.134 90.8289 146.233 90.696C146.333 90.5643 146.396 90.3942 146.421 90.1857L146.695 87.964L148.971 87.6458C149.19 87.6153 149.367 87.5509 149.501 87.4525C149.635 87.3541 149.711 87.2187 149.729 87.0462C149.75 86.8748 149.71 86.7206 149.609 86.5835C149.508 86.4464 149.358 86.3299 149.16 86.2342L147.072 85.2154L147.389 82.9944C147.42 82.7803 147.404 82.5948 147.342 82.438C147.282 82.2823 147.174 82.1654 147.017 82.0873C146.858 82.008 146.697 81.9908 146.534 82.0357C146.374 82.0817 146.217 82.1814 146.065 82.3349L144.483 83.9261L142.409 82.8719C142.215 82.7729 142.033 82.7243 141.863 82.7261C141.693 82.728 141.546 82.7878 141.423 82.9055C141.297 83.0244 141.234 83.168 141.235 83.3363C141.239 83.5035 141.294 83.6834 141.4 83.8759L142.518 85.884L140.909 87.4409C140.758 87.5865 140.66 87.7391 140.616 87.8988C140.571 88.0584 140.588 88.2151 140.666 88.3688Z" fill="white" fill-opacity="0.9"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M136.929 80.493C137.395 78.0879 140.121 79.674 138.264 81.2575C140.573 80.4584 140.558 83.6048 138.259 82.796C140.119 84.3923 137.378 85.9525 136.935 83.5603C136.469 85.9654 133.753 84.3959 135.6 82.7957C133.284 83.6212 133.299 80.4748 135.605 81.2572C133.738 79.6873 136.486 78.1007 136.929 80.493Z" fill="white" fill-opacity="0.9"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M141.317 92.4697C141.591 91.0518 143.198 91.9869 142.104 92.9205C143.465 92.4494 143.456 94.3044 142.1 93.8275C143.197 94.7686 141.581 95.6885 141.32 94.2781C141.045 95.6961 139.444 94.7708 140.533 93.8274C139.167 94.314 139.176 92.459 140.536 92.9203C139.435 91.9948 141.055 91.0593 141.317 92.4697ZM141.211 93.1997C141.31 93.1426 141.444 93.17 141.501 93.2684C141.558 93.3668 141.52 93.5067 141.421 93.5637C141.322 93.6208 141.192 93.5778 141.135 93.4794C141.079 93.3811 141.112 93.2567 141.211 93.1997Z" fill="white" fill-opacity="0.9"/>',
                        '<path d="M141.465 77.0869C141.683 77.417 141.648 77.7029 141.359 77.9448C141.238 78.0464 141.097 78.0954 140.937 78.0918C140.777 78.0881 140.637 78.0328 140.518 77.9257C139.983 77.428 139.551 77.0601 139.224 76.822C138.897 76.5733 138.588 76.4385 138.295 76.4176C138.008 76.3919 137.661 76.476 137.254 76.6697C136.847 76.8529 136.294 77.1299 135.593 77.5008C135.267 77.6752 134.993 77.6292 134.77 77.3629C134.668 77.2413 134.618 77.1004 134.621 76.94C134.624 76.7797 134.679 76.64 134.786 76.5211C135.311 75.9524 135.706 75.4925 135.972 75.1415C136.238 74.7905 136.383 74.4662 136.409 74.1687C136.434 73.8711 136.346 73.5312 136.143 73.149C135.946 72.762 135.642 72.2529 135.23 71.6217C135.023 71.2926 135.061 71.0095 135.344 70.7725C135.632 70.5306 135.92 70.5457 136.207 70.8176C136.737 71.3095 137.166 71.6799 137.492 71.9286C137.814 72.1716 138.119 72.3006 138.406 72.3156C138.694 72.3307 139.044 72.2442 139.456 72.0563C139.864 71.8625 140.415 71.5826 141.11 71.2165C141.446 71.0431 141.723 71.0867 141.942 71.3472C142.175 71.625 142.152 71.9201 141.874 72.2325C141.37 72.8031 140.99 73.2644 140.735 73.6164C140.48 73.9683 140.34 74.2931 140.315 74.5906C140.289 74.8882 140.375 75.2252 140.573 75.6016C140.771 75.978 141.068 76.4731 141.465 77.0869Z" fill="white" fill-opacity="0.9"/>',
                        '<circle cx="129" cy="78" r="2" fill="white" fill-opacity="0.9"/>',
                        '<ellipse cx="137.5" cy="90" rx="1.5" ry="1" fill="white" fill-opacity="0.9"/>',
                        '<ellipse cx="151.5" cy="90" rx="1.5" ry="2" fill="white" fill-opacity="0.9"/>',
                        '<circle cx="65" cy="75" r="6" fill="white"/>'
                    )
                )
            );
    }
}
