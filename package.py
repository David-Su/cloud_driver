import json
import os
import shutil

def main():
    with open("flavors.json", "r") as f:
        flavors = json.load(f)
        for flavor in flavors:
            cmd = 'flutter build web ' \
                  '--dart-define=CHANNEL=%s ' \
                  '--base-href=%s ' \
                  '--web-renderer html ' % (flavor["channel"], '/%s/' % (flavor["baseHref"]))
            print("执行-命令->" + cmd)
            os.system(cmd)
            print("执行-web目录改名-> %s" % (flavor["baseHref"]))
            target_dir = 'build/%s' % (flavor["baseHref"])
            if os.path.exists(target_dir):
                shutil.rmtree(target_dir)
            os.rename('build/web', target_dir)


if __name__ == "__main__":
    main()
