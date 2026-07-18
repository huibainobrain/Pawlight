-- Account deletion (required for App Store review, Guideline 5.1.1(v)) needs
-- deleting a User to cascade through their Pet(s) and everything owned by
-- those pets. Every other FK in the schema already cascades from Pet
-- (Photo, Share, Letter) and from Share (Hug), and Entitlement already
-- cascades from User directly. Pet -> User was the one link still left as
-- ON DELETE RESTRICT from the baseline migration.
ALTER TABLE "Pet" DROP CONSTRAINT "Pet_userId_fkey";
ALTER TABLE "Pet" ADD CONSTRAINT "Pet_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
