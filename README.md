CoreDataMinimal2
================

This project contains a core data stack with iCloud support.
The purpose of the class DCCoreDataManager is to provide a simple interface
to a view controller that allows switching between a Local or an iCloud store, and
also handle system events such as disable iCloud or login with a different account.

There is no migration between stores implemented.

Also, the aim with the scheme of when to ask the DCCoreDataManager for decisions is roughly:
 * The first time the app has iCloud access, the view controller is given a chance to relay this question to the user. The question is if Local or iCloud store should be used.
 * If the user choses iCLoud, and iCloud later becomes unavailable, the user is simply notified that there has been a switch to local store. In this case, if later iCloud becomes available again, the user can shose iCloud store again.
 * If iCloud store is used, and the user logs in with another account, the view controller gets a chance to decide if local or iCloud store is used.

I'm not perfectly sure if scheme of working is submitable to apple, but it was a basic model that I needed.
