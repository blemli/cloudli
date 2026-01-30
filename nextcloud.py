#!/usr/bin/env python

import fcntl
import os
import subprocess
import sys
from pathlib import Path

import click
from dotenv import load_dotenv

NEXTCLOUD_DIR = Path(__file__).parent / "nextcloud"
TINYVAULT_ENV = Path.home() / "tinyvault" / ".env"
LOCK_FILE = Path(__file__).parent / ".nextcloud.lock"


def _get_credentials():
    """Load and return Nextcloud password from tinyvault."""
    load_dotenv(TINYVAULT_ENV)
    password = os.getenv("NEXTCLOUD_PASSWORD")
    if not password:
        raise click.ClickException("NEXTCLOUD_PASSWORD not found in tinyvault .env")
    return password


def _run_sync():
    """Run nextcloudcmd and return (success, output)."""
    password = _get_credentials()
    NEXTCLOUD_DIR.mkdir(exist_ok=True)

    result = subprocess.run(
        [
            "nextcloudcmd",
            "--non-interactive",
            str(NEXTCLOUD_DIR),
            f"https://cloudli:{password}@cloud.problem.li",
        ],
        capture_output=True,
        text=True,
    )
    return result.returncode == 0, result.stdout + result.stderr


@click.group()
def cli():
    """Nextcloud sync management."""
    pass


@cli.command()
def status():
    """Run sync and report status: syncing, synced, or error."""
    LOCK_FILE.touch()
    lock_fd = open(LOCK_FILE, "w")

    # Try to acquire lock without blocking
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        click.echo("syncing")
        return

    try:
        success, output = _run_sync()
        if success:
            click.echo("synced")
        else:
            click.echo("error", err=True)
            if output:
                click.echo(output, err=True)
            sys.exit(1)
    finally:
        fcntl.flock(lock_fd, fcntl.LOCK_UN)
        lock_fd.close()


@cli.command()
def sync():
    """Start Nextcloud sync (blocks if already syncing)."""
    LOCK_FILE.touch()
    lock_fd = open(LOCK_FILE, "w")

    # Try to acquire lock without blocking
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        click.echo("Sync already in progress")
        return

    try:
        click.echo("Syncing...")
        success, output = _run_sync()
        if success:
            click.echo("Done")
        else:
            click.echo("Sync failed", err=True)
            if output:
                click.echo(output, err=True)
            sys.exit(1)
    finally:
        fcntl.flock(lock_fd, fcntl.LOCK_UN)
        lock_fd.close()


@cli.command()
def stop():
    """Stop the Nextcloud sync."""
    result = subprocess.run(
        ["pgrep", "-f", "nextcloudcmd"],
        capture_output=True,
    )
    if result.returncode != 0:
        click.echo("Not running")
        return

    subprocess.run(["pkill", "-f", "nextcloudcmd"])
    click.echo("Stopped")


@cli.command()
def size():
    """Return size of the nextcloud folder."""
    if not NEXTCLOUD_DIR.exists():
        click.echo("0")
        return

    result = subprocess.run(
        ["du", "-sh", str(NEXTCLOUD_DIR)],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        size_str = result.stdout.split()[0]
        click.echo(size_str)
    else:
        click.echo("0")


if __name__ == "__main__":
    cli()
