import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--bucket')
parser.add_argument('--object')

if __name__ == "__main__":
    args = parser.parse_args()

    print(args.bucket)
    print(args.object)
