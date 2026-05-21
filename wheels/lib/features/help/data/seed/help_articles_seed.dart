import '../../domain/entities/help_category.dart';
import '../models/help_article_model.dart';

const String _seedCorpusVersion = '2026-05-20';

DateTime _seedDate() => DateTime.utc(2026, 5, 20);

List<HelpArticleModel> buildSeedHelpArticles() {
  final updatedAt = _seedDate();
  return <HelpArticleModel>[
    // ---------- Account ----------
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'acc_verify_uniandes',
      slug: 'verifying-your-uniandes-account',
      title: 'Verifying your Uniandes account',
      summary:
          'Wheels only enables rides between verified Uniandes students. Here is how to confirm your institutional email.',
      body:
          '## Why verification matters\n\nWheels keeps the ride pool restricted to verified Uniandes students so that drivers and passengers know who they are sharing with. Without verification you cannot publish rides, apply for rides, or write reviews.\n\n## Steps\n\n1. Open the app and tap **Profile**.\n2. Tap **Verify Uniandes email**.\n3. Open the email from `no-reply@wheels.uniandes.edu.co` and tap the confirmation link.\n4. Return to the app and pull down to refresh; your profile will show the **Verified** badge.\n\n## Troubleshooting\n\n- The confirmation link expires after 30 minutes. If it expired, request a new one from the same screen.\n- Check your spam folder if you do not see the email within two minutes.\n- If you still cannot verify, contact support from this Help Center.',
      category: HelpCategory.account,
      tags: const ['verification', 'email', 'uniandes', 'profile'],
      updatedAt: updatedAt,
      upvotes: 142,
      downvotes: 6,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'acc_update_photo',
      slug: 'updating-your-profile-photo',
      title: 'Updating your profile photo',
      summary:
          'A real profile photo makes pickups smoother. Here is how to upload or replace yours.',
      body:
          '## Update your photo\n\n1. Tap **Profile**, then your current avatar.\n2. Choose **Take photo** or **Upload from gallery**.\n3. Crop and confirm.\n\n## Photo requirements\n\n- Your face must be clearly visible. Sunglasses and full helmets are not allowed.\n- No group photos. Drivers and passengers need to recognize you alone.\n- Avoid screenshots or memes. Wheels reserves the right to remove non-compliant photos.\n\n## What if my photo gets rejected?\n\nYou will receive an in-app notification with the reason. You can upload a new one immediately.',
      category: HelpCategory.account,
      tags: const ['profile', 'photo', 'avatar'],
      updatedAt: updatedAt,
      upvotes: 73,
      downvotes: 2,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'acc_switch_role',
      slug: 'switching-between-driver-and-passenger',
      title: 'Switching between driver and passenger roles',
      summary:
          'You can hold both roles in the same account. Switch with one tap from your Profile screen.',
      body:
          '## How to switch\n\n1. Open **Profile**.\n2. Tap the role chip next to your name.\n3. Choose **Driver** or **Passenger**.\n\nThe app reloads the home screen with the views relevant to the role you picked. Your history, reviews, and trust score remain attached to your account, not to the role.\n\n## Becoming a driver for the first time\n\nIf you have not unlocked driver mode yet, the switch will open the **Become a driver** flow. You will be asked for vehicle data, driver license photos, and you will have to accept the Wheels driver agreement.\n\n## Limitations\n\n- Role switching requires an active internet connection.\n- You cannot switch role while you are inside an active ride.',
      category: HelpCategory.account,
      tags: const ['role', 'driver', 'passenger', 'profile'],
      updatedAt: updatedAt,
      upvotes: 58,
      downvotes: 4,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'acc_password_recovery',
      slug: 'recovering-your-password',
      title: 'Recovering your password',
      summary:
          'Reset your Wheels password using your Uniandes email. The reset link expires after one hour.',
      body:
          '## Reset your password\n\n1. From the login screen, tap **Forgot password**.\n2. Enter your Uniandes email.\n3. Open the email titled **Reset your Wheels password** and tap the link.\n4. Set a new password (at least 8 characters, one number, one symbol).\n5. Return to the app and log in with the new password.\n\n## The link does not work\n\nThe reset link expires after one hour. If you opened it after that window, request a new reset from the login screen.\n\n## I do not have access to my Uniandes email anymore\n\nContact support from this Help Center and include your full name and student ID. Recovery in those cases is manual and may take 24 hours.',
      category: HelpCategory.account,
      tags: const ['password', 'reset', 'login', 'email'],
      updatedAt: updatedAt,
      upvotes: 211,
      downvotes: 9,
    ),

    // ---------- Payments ----------
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'pay_add_method',
      slug: 'adding-a-payment-method',
      title: 'Adding a payment method',
      summary:
          'Wheels uses Mercado Pago for card payments and supports manual bank transfers as a fallback.',
      body:
          '## Add a card\n\n1. Open **Wallet**, then **Payment methods**.\n2. Tap **Add card** and follow the Mercado Pago flow.\n3. Wheels never stores card numbers directly; tokens are kept by Mercado Pago.\n\n## Use bank transfer\n\nWhen a driver enables direct bank transfer for a ride, the passenger sees the driver bank data after applying. Mark the ride as **Transfer sent** once you complete the transfer from your bank app.\n\n## Failures\n\n- If a card is rejected, double-check expiration and CVV. Some banks block international transactions by default.\n- For Mercado Pago errors, the in-app banner usually contains a Mercado Pago error code; share that code with support when needed.',
      category: HelpCategory.payments,
      tags: const ['payment', 'card', 'mercado pago', 'transfer'],
      updatedAt: updatedAt,
      upvotes: 184,
      downvotes: 11,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'pay_refunds',
      slug: 'how-refunds-work',
      title: 'How refunds work',
      summary:
          'Card refunds are automatic when a driver cancels. Manual transfers must be reconciled with the driver.',
      body:
          '## Card refund (Mercado Pago)\n\nIf a driver cancels a ride before departure, Mercado Pago triggers a refund automatically. It can take up to 10 business days for the amount to appear back on your card statement.\n\n## Manual bank transfer refund\n\nFor manual transfers, the driver is responsible for sending the money back. If a driver does not refund a manual transfer, report it through this Help Center; the driver trust score will be affected.\n\n## Partial refunds\n\nWheels does not currently process partial refunds. If a ride started but ended early for safety reasons, contact support so the case can be reviewed manually.',
      category: HelpCategory.payments,
      tags: const ['refund', 'cancellation', 'mercado pago', 'transfer'],
      updatedAt: updatedAt,
      upvotes: 96,
      downvotes: 14,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'pay_withdraw_earnings',
      slug: 'withdrawing-your-driver-earnings',
      title: 'Withdrawing your driver earnings',
      summary:
          'Drivers can withdraw available balance from the Wallet screen. Withdrawals require an active internet connection.',
      body:
          '## Request a withdrawal\n\n1. Open **Wallet** as a driver.\n2. Check the **Available balance** card.\n3. Tap **Withdraw**, fill in the amount and target bank account.\n4. Confirm. Wheels will mark the amount as **Pending withdrawal**.\n\n## Processing time\n\nWithdrawals are processed within two business days. Once the bank confirms the transfer, the balance moves out of **Pending withdrawal** and a notification is sent.\n\n## Offline behavior\n\nIf the device is offline, the withdrawal form is saved locally as a draft but the request is **not** submitted. Reconnect and re-submit from the same screen.',
      category: HelpCategory.payments,
      tags: const ['withdraw', 'earnings', 'driver', 'wallet'],
      updatedAt: updatedAt,
      upvotes: 121,
      downvotes: 5,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'pay_pending_status',
      slug: 'why-a-payment-is-marked-as-pending',
      title: 'Why a payment is marked as pending',
      summary:
          'A payment stays pending until Mercado Pago or the driver confirms it. Here is how to interpret each status.',
      body:
          '## Pending verification\n\nWhen you finish a card checkout, Mercado Pago needs a few seconds (sometimes minutes) to confirm the transaction. The app shows **Payment pending verification** during that window. You can close the app safely; the status updates automatically when the backend reconciles it.\n\n## Pending transfer\n\nFor manual transfers, **Pending** means the driver has not confirmed receipt yet. After the driver marks the transfer as received, the status changes to **Paid**.\n\n## Stuck on pending for more than 30 minutes?\n\n- For cards, check your bank statement to confirm the charge actually happened. If it did not, simply retry the payment.\n- For transfers, contact the driver via the in-app chat to nudge confirmation.',
      category: HelpCategory.payments,
      tags: const ['payment', 'pending', 'status', 'verification'],
      updatedAt: updatedAt,
      upvotes: 88,
      downvotes: 7,
    ),

    // ---------- Rides ----------
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'ride_publish_first',
      slug: 'publishing-your-first-ride',
      title: 'Publishing your first ride',
      summary:
          'A short walkthrough for drivers publishing their first ride on Wheels.',
      body:
          '## Steps\n\n1. Switch your role to **Driver**.\n2. Tap **Publish a ride** from the dashboard.\n3. Fill origin (the app suggests your current location), destination, date, time, available seats, price per seat, and notes.\n4. Pick a payment option: **Card or direct transfer** or **Direct bank transfer only**.\n5. Tap **Publish**.\n\n## Best practices\n\n- Be on time. Late cancellations affect your **Driver Reliability Score**.\n- Set a fair price. The app suggests a price band based on similar routes.\n- Keep notes short but useful, for example: "Pickup at the South Gate, look for the red Mazda 2".\n\n## Offline behavior\n\nWheels saves your ride form as a local draft as you type. If the device loses connectivity, the draft is restored next time you open the screen.',
      category: HelpCategory.rides,
      tags: const ['publish', 'driver', 'ride', 'create'],
      updatedAt: updatedAt,
      upvotes: 167,
      downvotes: 3,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'ride_search_and_book',
      slug: 'searching-and-booking-a-ride',
      title: 'Searching and booking a ride',
      summary:
          'How passengers can find an available ride and reserve a seat.',
      body:
          '## Search\n\n1. From the dashboard, tap **Find a ride**.\n2. Pick a date and optionally a time window.\n3. Filter by origin neighborhood, destination, price range, or payment method.\n4. Sort by **Departure time** or **Price**.\n\n## Book a seat\n\n1. Tap a ride to open **Ride details**.\n2. Tap **Apply** to reserve a seat.\n3. If the ride requires card payment, the checkout flow opens immediately.\n4. After the driver accepts (and payment is confirmed when applicable), the ride moves to **Active**.\n\n## Offline behavior\n\nThe last successful search is saved locally. If you open the search screen offline, Wheels restores those results and shows a banner indicating they may be stale.',
      category: HelpCategory.rides,
      tags: const ['search', 'book', 'passenger', 'ride'],
      updatedAt: updatedAt,
      upvotes: 132,
      downvotes: 6,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'ride_cancel_before_departure',
      slug: 'cancelling-a-ride-before-departure',
      title: 'Cancelling a ride before departure',
      summary:
          'Cancellations affect your trust score. Here is how penalties work depending on how close to departure you cancel.',
      body:
          '## How to cancel\n\nOpen the ride from **Active rides** and tap **Cancel ride**. Confirm in the dialog.\n\n## Trust score penalties (drivers)\n\n- More than 6 hours before departure: minor penalty.\n- 1 to 6 hours before departure: medium penalty.\n- Less than 1 hour: high penalty.\n- During an active ride: highest penalty plus a manual review.\n\n## Passenger refunds\n\nWhen a driver cancels, passengers who paid by card get an automatic refund. Drivers who used manual transfer must refund manually.\n\n## Offline cancellations\n\nIf you cancel offline, the action is stored as **Pending sync** and applied as soon as connectivity returns. Be aware that the timestamp used to compute the penalty is the **server-confirmed time**, not when you tapped Cancel.',
      category: HelpCategory.rides,
      tags: const ['cancel', 'ride', 'trust score', 'refund'],
      updatedAt: updatedAt,
      upvotes: 154,
      downvotes: 22,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'ride_statuses_explained',
      slug: 'understanding-ride-statuses',
      title: 'Understanding ride statuses',
      summary:
          'Open, in progress, completed, cancelled. What each status means and what you can do in it.',
      body:
          '## Open\n\nThe ride is published and accepting applications. Passengers can apply; the driver can edit or cancel.\n\n## In progress\n\nThe driver tapped **Start ride**. Routes and pickup metadata are now locked. Cancellation from this state is restricted and incurs the highest penalty for drivers.\n\n## Completed\n\nThe driver tapped **Finish ride** and confirmed final payment statuses for each passenger. Reviews become available for both sides.\n\n## Cancelled\n\nEither the driver cancelled, or the ride expired without departure. Refunds are processed automatically for card payments.',
      category: HelpCategory.rides,
      tags: const ['status', 'ride', 'lifecycle'],
      updatedAt: updatedAt,
      upvotes: 71,
      downvotes: 2,
    ),

    // ---------- Safety ----------
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'saf_report_user',
      slug: 'reporting-an-unsafe-driver-or-passenger',
      title: 'Reporting an unsafe driver or passenger',
      summary:
          'Reports are reviewed by the Wheels safety team within 24 hours. Severe cases trigger immediate suspension.',
      body:
          '## How to report\n\n1. Open the ride from your history.\n2. Tap **Report a problem**.\n3. Pick a category (unsafe driving, harassment, no-show, payment dispute, other).\n4. Add as much detail as you can and attach screenshots if relevant.\n5. Submit.\n\n## What happens next\n\nA member of the safety team reviews your report within 24 hours. You may be contacted for more context. Severe categories (harassment, threats, accidents) trigger immediate temporary suspension of the reported user while the investigation is open.\n\n## Anonymity\n\nReports are visible only to the safety team. The reported user does not see who filed the report.',
      category: HelpCategory.safety,
      tags: const ['report', 'safety', 'unsafe', 'harassment'],
      updatedAt: updatedAt,
      upvotes: 219,
      downvotes: 1,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'saf_feel_unsafe',
      slug: 'what-to-do-if-you-feel-unsafe-during-a-ride',
      title: 'What to do if you feel unsafe during a ride',
      summary:
          'Trust your instincts, end the ride at a safe location, and use the in-app emergency tools.',
      body:
          '## Immediate actions\n\n1. Ask the driver to stop at the next safe, well-lit, public place (a gas station, a campus gate, a 24/7 store).\n2. Exit the vehicle.\n3. Tap **Share trip** to send your live location to a trusted contact.\n4. If you are in immediate danger, call **123** (Colombia general emergency line).\n\n## After you are safe\n\n- File a report in the app within 24 hours.\n- Take note of details: vehicle plate, time, location, and what happened.\n\n## Wheels safety commitments\n\n- We never charge cancellation penalties when a safety report is filed.\n- The reported user is suspended pending investigation in severe cases.',
      category: HelpCategory.safety,
      tags: const ['safety', 'emergency', 'unsafe', 'share trip'],
      updatedAt: updatedAt,
      upvotes: 248,
      downvotes: 0,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'saf_verify_car',
      slug: 'verifying-you-are-getting-into-the-right-car',
      title: 'Verifying you are getting into the right car',
      summary:
          'Before opening the door, confirm plate, driver name, and vehicle color. Never share your verification code first.',
      body:
          '## Before you get in\n\n1. Check the **license plate** in the ride detail screen against the actual car.\n2. Confirm the **driver name and photo** match.\n3. Confirm the **vehicle model and color** match what is shown in the app.\n4. Ask the driver: "Who are you here to pick up?" Let them tell you your name first.\n\n## Verification code\n\nWheels does not yet use a one-time verification code. Until that feature ships, the four checks above are the recommended workflow.\n\n## Group rides\n\nWhen you are sharing a ride with others, you may not be the first pickup. The app shows the pickup order so you can recognize the right stop.',
      category: HelpCategory.safety,
      tags: const ['safety', 'verify', 'pickup', 'plate'],
      updatedAt: updatedAt,
      upvotes: 178,
      downvotes: 3,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'saf_share_trip',
      slug: 'sharing-your-trip-with-a-contact',
      title: 'Sharing your trip with a contact',
      summary:
          'You can share a live link with a friend or family member so they can follow the route in real time.',
      body:
          '## Enable Share Trip\n\n1. Inside an active ride, tap **Share trip**.\n2. Pick a contact from your phone or paste a link in any chat app.\n3. The link shows live location, ETA, and driver info; it expires when the ride ends.\n\n## Privacy\n\nOnly the people you give the link to can see your trip. The link cannot be reused after the ride ends; opening it later shows only a "Trip ended" page.\n\n## Tip\n\nMany users set up a **Saved contact** in Profile so the **Share trip** action sends to that person with one tap.',
      category: HelpCategory.safety,
      tags: const ['safety', 'share', 'live', 'contact'],
      updatedAt: updatedAt,
      upvotes: 134,
      downvotes: 5,
    ),

    // ---------- Drivers ----------
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'drv_reliability_score',
      slug: 'your-driver-reliability-score-explained',
      title: 'Your Driver Reliability Score explained',
      summary:
          'Your score is a number from 0 to 100. It goes up with completed rides and down with late cancellations.',
      body:
          '## How it is computed\n\nEvery driver starts at **100**. The score is recalculated by the backend after every completed ride or cancellation:\n\n- **Completed ride**: small positive bump.\n- **Cancellation more than 6 hours before departure**: small negative.\n- **Cancellation between 1 and 6 hours**: medium negative.\n- **Cancellation under 1 hour**: large negative.\n- **No-show**: largest negative.\n\nThe score is clamped between 0 and 100.\n\n## Where it shows\n\nPassengers see it on the ride card and your profile. Below 60 your rides receive less visibility in search results; below 40, new ride publishing is temporarily disabled.\n\n## How to recover\n\nThere is no shortcut. Complete rides on time. The score recovers as new successful trips push out old penalties.',
      category: HelpCategory.drivers,
      tags: const ['driver', 'trust score', 'reliability', 'penalty'],
      updatedAt: updatedAt,
      upvotes: 192,
      downvotes: 18,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'drv_keep_score_high',
      slug: 'how-to-keep-your-trust-score-high',
      title: 'How to keep your trust score high',
      summary:
          'Four habits that protect your driver reliability score over time.',
      body:
          '## 1. Publish realistic rides\n\nDo not publish rides you are not confident you can complete. Only publish when your schedule is stable.\n\n## 2. Communicate early\n\nIf you must cancel, do it as far in advance as possible. The penalty for a 24-hour-ahead cancellation is small; the penalty for a 30-minute-ahead cancellation is large.\n\n## 3. Be on time\n\nLeave early enough to absorb traffic. Repeated late pickups affect both your trust score and your ratings.\n\n## 4. Keep the app up to date\n\nNew safety and reconciliation features ship every sprint. Outdated app versions may fail to reconcile cancellation timestamps correctly.',
      category: HelpCategory.drivers,
      tags: const ['driver', 'trust score', 'tips'],
      updatedAt: updatedAt,
      upvotes: 108,
      downvotes: 4,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'drv_pickup_zones',
      slug: 'setting-your-preferred-pickup-zones',
      title: 'Setting your preferred pickup zones',
      summary:
          'Save frequent origins so publishing a ride only takes a couple of taps.',
      body:
          '## Save a zone\n\nFrom **Saved destinations**, tap **Add destination** and pick a place from the map or autocomplete. Common examples: the Uniandes main gate, the South parking lot, your home neighborhood.\n\n## Use a saved zone\n\nIn **Publish a ride**, tap the **Origin** field and select a saved destination chip. The fields autocomplete and you can tweak before publishing.\n\n## Offline\n\nSaved destinations are stored locally first and synced to the cloud when you are online. Adds and edits made offline are flushed automatically once connectivity returns.',
      category: HelpCategory.drivers,
      tags: const ['driver', 'destinations', 'pickup', 'origin'],
      updatedAt: updatedAt,
      upvotes: 84,
      downvotes: 1,
    ),
    HelpArticleModel(
      version: HelpArticleModel.currentVersion,
      id: 'drv_first_time_best_practices',
      slug: 'best-practices-for-first-time-drivers',
      title: 'Best practices for first-time drivers',
      summary:
          'Six small habits that make your first rides feel professional and safe.',
      body:
          '## 1. Confirm passenger identity\n\nAsk the passenger to say their name first. Cross-check with the in-app profile.\n\n## 2. Keep the car clean\n\nA clean car beats a fancy car. Empty bottles and crumbs in the back seat hurt your ratings more than anything else.\n\n## 3. Drive defensively\n\nWheels is a campus app. Other students notice careless driving and you will get reported.\n\n## 4. No music battles\n\nAsk before changing the audio source. Volume matters more than genre.\n\n## 5. Confirm payment method\n\nBefore starting the ride, confirm with each passenger which payment method they will use. Manual transfer passengers should send the transfer before the ride ends.\n\n## 6. Mark the ride complete on time\n\nThe **Finish ride** step locks the payment status for each passenger. Do it as soon as the last passenger steps out.',
      category: HelpCategory.drivers,
      tags: const ['driver', 'best practices', 'first time'],
      updatedAt: updatedAt,
      upvotes: 145,
      downvotes: 6,
    ),
  ];
}

String get seedHelpCorpusVersion => _seedCorpusVersion;
